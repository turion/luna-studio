---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Flowbox Team <contact@flowbox.io>, 2014
-- Proprietary and confidential
-- Unauthorized copying of this file, via any medium is strictly prohibited
---------------------------------------------------------------------------
module Luna.Interpreter.Session.Cache.Cache where

import           Control.Monad.State hiding (mapM, mapM_)
import qualified Data.Map            as Map
import qualified Data.Maybe          as Maybe

import           Flowbox.Data.MapForest                      (MapForest)
import qualified Flowbox.Data.MapForest                      as MapForest
import           Flowbox.Prelude
import           Flowbox.System.Log.Logger
import           Luna.Interpreter.Session.Cache.Info         (CacheInfo (CacheInfo))
import qualified Luna.Interpreter.Session.Cache.Info         as CacheInfo
import           Luna.Interpreter.Session.Cache.Status       (CacheStatus)
import qualified Luna.Interpreter.Session.Cache.Status       as CacheStatus
import qualified Luna.Interpreter.Session.Data.CallData      as CallData
import           Luna.Interpreter.Session.Data.CallDataPath  (CallDataPath)
import qualified Luna.Interpreter.Session.Data.CallDataPath  as CallDataPath
import           Luna.Interpreter.Session.Data.CallPoint     (CallPoint)
import           Luna.Interpreter.Session.Data.CallPointPath (CallPointPath)
import           Luna.Interpreter.Session.Data.Hash          (Hash)
import           Luna.Interpreter.Session.Data.VarName       (VarName)
import qualified Luna.Interpreter.Session.Data.VarName       as VarName
import qualified Luna.Interpreter.Session.Env                as Env
import           Luna.Interpreter.Session.Session            (Session)
import qualified Luna.Interpreter.Session.Session            as Session



logger :: LoggerIO
logger = getLoggerIO "Flowbox.Interpreter.Session.Cache.Cache"


dump :: CallPointPath -> Maybe Hash -> Session ()
dump callPointPath mhash = do
    let varName = VarName.mk mhash callPointPath
    logger debug $ "Dumping " ++ varName
    Session.runStmt $ "print " ++ varName


dumpAll :: Session ()
dumpAll = logger trace =<< MapForest.draw <$> cached


isDirty :: CallPointPath -> Session Bool
isDirty = onCacheInfo
    (\cacheInfo -> return $ cacheInfo ^. CacheInfo.status /= CacheStatus.Ready)
    (return True)


status :: CallPointPath -> Session CacheStatus
status = onCacheInfo
    (return . view CacheInfo.status)
    (return CacheStatus.Modified)


setStatus :: CacheStatus -> CallPointPath -> Session ()
setStatus newStatus = modifyCacheInfo (CacheInfo.status .~ newStatus)


dependency :: [VarName] -> CallPointPath -> Session (Maybe VarName)
dependency predVarNames = onCacheInfo
    (return . Map.lookup predVarNames . view CacheInfo.dependencies)
    (return Nothing)


recentVarName :: CallPointPath -> Session VarName
recentVarName = onCacheInfo
    (return . view CacheInfo.recentVarName)
    (return "")


setRecentVarName :: VarName -> CallPointPath -> Session ()
setRecentVarName varName = modifyCacheInfo (CacheInfo.recentVarName .~ varName)


modifyCacheInfo :: (CacheInfo -> CacheInfo) -> CallPointPath ->  Session ()
modifyCacheInfo f callPointPath = onCacheInfo
    (\cacheInfo -> modify (Env.cached %~ MapForest.insert callPointPath (f cacheInfo)))
    (return ())
    callPointPath


onCacheInfo :: (CacheInfo -> Session a) -> Session a -> CallPointPath -> Session a
onCacheInfo f alternative callPointPath =
    Maybe.maybe alternative f . MapForest.lookup callPointPath =<< cached


put :: CallDataPath -> [VarName] -> VarName -> Session ()
put callDataPath predVarNames varName = do
    let callPointPath = CallDataPath.toCallPointPath callDataPath
    mcacheInfo <- lookupCacheInfo callPointPath
    oldStatus  <- status callPointPath
    let updatedStatus = if oldStatus == CacheStatus.NonCacheable
                            then oldStatus
                            else CacheStatus.Ready
        existingDeps = Maybe.maybe Map.empty (view CacheInfo.dependencies) mcacheInfo
        dependencies = Map.insert predVarNames varName existingDeps
        cacheInfo    = CacheInfo (last callDataPath ^. CallData.parentDefID)
                                 (last callDataPath ^. CallData.parentBC)
                                 updatedStatus varName dependencies

    modify (Env.cached %~ MapForest.insert callPointPath cacheInfo)


delete :: CallPointPath -> Session ()
delete callPointPath = modify $ Env.cached %~ MapForest.delete callPointPath


cached :: Session (MapForest CallPoint CacheInfo)
cached = gets (view Env.cached)


lookupCacheInfo :: CallPointPath -> Session (Maybe CacheInfo)
lookupCacheInfo callPointPath = MapForest.lookup callPointPath <$> cached
