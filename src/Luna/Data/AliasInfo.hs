---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# LANGUAGE TemplateHaskell #-}

module Luna.Data.AliasInfo where

import Flowbox.Prelude

import GHC.Generics        (Generic)


import           Data.IntMap  (IntMap)
import           Data.Map     (Map)
import           Luna.ASTNew.AST (AST, ID)
import qualified Luna.ASTNew.AST as AST
import qualified Data.Maps    as Map


----------------------------------------------------------------------
-- Data types
----------------------------------------------------------------------

type IDMap = IntMap


data Error  = LookupError {key :: String}
            deriving (Show, Eq, Generic, Read)


data Scope = Scope { _varnames  :: Map String ID
                   , _typenames :: Map String ID 
                   } deriving (Show, Eq, Generic, Read)

makeLenses (''Scope)


data AliasInfo = AliasInfo  { _scope   :: IDMap Scope
                            , _alias   :: IDMap ID
                            , _orphans :: IDMap Error
                            , _parent  :: IDMap ID
                            } deriving (Show, Eq, Generic, Read)

makeLenses (''AliasInfo)


----------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------

regParent  id pid  = parent %~ Map.insert id pid
regVarName pid id name info = setScope info pid $ Scope (vnmap & at name ?~ id) tnmap where
    (vnmap, tnmap) = scopeLookup pid info

regOrphan id err = orphans %~ Map.insert id err

regTypeName pid id name info = setScope info pid $ Scope vnmap (tnmap & at name ?~ id) where
    (vnmap, tnmap) = scopeLookup pid info

setScope info id s = info & scope.at id ?~ s

scopeLookup pid info = case Map.lookup pid (_scope info) of
        Nothing          -> (mempty, mempty)
        Just (Scope v t) -> (v,t)

registerAlias :: ID              -- ^ Variable that we seek aliases of: ID
              -> String          -- ^ Variable that we seek aliases of: Name
              -> ID              -- ^ Current scope ID
              -> AliasInfo
              -> Maybe AliasInfo -- ^ New map of aliases if succeeded
registerAlias ident name scopeID aliasInfo = updateAliasInfo <$> getVariableID
  where
    updateAliasInfo :: ID -> AliasInfo
    updateAliasInfo tid = aliasInfo & alias . at ident ?~ tid
    getVariableID :: Maybe ID
    getVariableID = aliasInfo ^? scope . ix scopeID . varnames . ix name

------------------------------------------------------------------------
-- Instances
------------------------------------------------------------------------

instance Monoid Scope where
    mempty      = Scope mempty mempty
    mappend a b = Scope (mappend (a ^. varnames)  (b ^. varnames))
                        (mappend (a ^. typenames) (b ^. typenames))


instance Monoid AliasInfo where
    mempty      = AliasInfo mempty mempty mempty mempty
    mappend a b = AliasInfo (mappend (a ^. scope)   (b ^. scope))
                            (mappend (a ^. alias)   (b ^. alias))
                            (mappend (a ^. orphans) (b ^. orphans))
                            (mappend (a ^. parent)  (b ^. parent))


instance Default Scope where
    def = mempty

instance Default AliasInfo where
    def = mempty