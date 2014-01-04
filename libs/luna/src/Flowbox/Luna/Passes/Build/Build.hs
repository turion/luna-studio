---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# LANGUAGE ConstraintKinds  #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE Rank2Types       #-}

module Flowbox.Luna.Passes.Build.Build where

import Control.Applicative
import Control.Monad.RWS   hiding (mapM, mapM_)

import qualified Flowbox.Luna.Data.AST.Module                   as ASTModule
import           Flowbox.Luna.Data.Source                       (Source)
import qualified Flowbox.Luna.Data.Source                       as Source
import qualified Flowbox.Luna.Passes.Analysis.FuncPool.FuncPool as FuncPool
import qualified Flowbox.Luna.Passes.Analysis.VarAlias.VarAlias as VarAlias
import           Flowbox.Luna.Passes.Build.BuildConfig          (BuildConfig (BuildConfig))
import qualified Flowbox.Luna.Passes.Build.BuildConfig          as BuildConfig
import qualified Flowbox.Luna.Passes.CodeGen.Cabal.Gen          as CabalGen
import qualified Flowbox.Luna.Passes.CodeGen.Cabal.Install      as CabalInstall
import qualified Flowbox.Luna.Passes.CodeGen.Cabal.Store        as CabalStore
import qualified Flowbox.Luna.Passes.CodeGen.HSC.HSC            as HSC
import qualified Flowbox.Luna.Passes.Pass                       as Pass
import           Flowbox.Prelude
--import           Flowbox.Luna.Passes.Pass                                (PassMonadIO)
import           Control.Monad.Trans.Either
import           Flowbox.Luna.Data.Pass.SourceMap                      (SourceMap)
import qualified Flowbox.Luna.Passes.Build.Diagnostics                 as Diagnostics
import qualified Flowbox.Luna.Passes.Source.File.Reader                as FileReader
import qualified Flowbox.Luna.Passes.Source.File.Writer                as FileWriter
import qualified Flowbox.Luna.Passes.Transform.AST.TxtParser.TxtParser as TxtParser
import qualified Flowbox.Luna.Passes.Transform.HAST.HASTGen.HASTGen    as HASTGen
import qualified Flowbox.Luna.Passes.Transform.SSA.SSA                 as SSA
import qualified Flowbox.System.Directory.Directory                    as Directory
import           Flowbox.System.Log.Logger
import qualified Flowbox.System.Platform                               as Platform
import           Flowbox.System.UniPath                                (UniPath)
import qualified Flowbox.System.UniPath                                as UniPath
import qualified Flowbox.Text.Show.Hs                                  as ShowHs

---- REMOVE !!!! JUST TESTING
--import qualified Flowbox.Luna.Data.AST.Zipper                          as Zipper
--import qualified Flowbox.Luna.Passes.Transform.Graph.Builder.Builder   as GraphBuilder
--import qualified Flowbox.Luna.Passes.Transform.Graph.Parser.Parser   as GraphParser
--import Debug.Trace as D
--import Text.Show.Pretty
---- REMOVE !!!! JUST TESTING

logger :: LoggerIO
logger = getLoggerIO "Flowbox.Luna.Passes.Build.Build"


srcFolder :: String
srcFolder = "src"


hsExt :: String
hsExt = ".hs"


cabalExt :: String
cabalExt = ".cabal"


tmpDirPrefix :: String
tmpDirPrefix = "lunac"


--run :: BuildConfig -> ASTModule.Module -> Pass.Result ()
run (BuildConfig name version libs ghcOptions cabalFlags buildType cfg diag) ast = do
    Diagnostics.printAST ast diag
    va   <- hoistEither =<< VarAlias.run ast
    Diagnostics.printVA va diag
    fp <- hoistEither =<< FuncPool.run ast
    Diagnostics.printFP fp diag
    ssa  <- hoistEither =<< SSA.run va ast
    Diagnostics.printSSA ssa diag
    hast <- hoistEither =<< HASTGen.run ssa fp
    Diagnostics.printHAST hast diag
    hsc  <- map (Source.transCode ShowHs.hsShow) <$> (hoistEither =<< HSC.run hast)
    Diagnostics.printHSC hsc diag


    ---- REMOVE !!!! JUST TESTING
    --let zipper = Zipper.mk ast
    --         >>= Zipper.focusFunction "test"
    --    focus  = fmap Zipper.getFocus zipper
    --    Just (Zipper.FunctionFocus expr) = focus

    --graph <- GraphBuilder.run va $ D.trace (ppShow expr) expr
    --logger info $ show graph

    --ast2 <- GraphParser.run graph expr
    --logger warning $ ppShow ast2

    ---- REMOVE !!!! JUST TESTING

    let allLibs = "base"
                : "flowboxM-core"
                : "template-haskell"
                : libs
                ++ if name /= "flowboxM-stdlib"
                      then ["flowboxM-stdlib"]
                      else []

    Directory.withTmpDirectory tmpDirPrefix (\tmpDir -> do
        writeSources tmpDir hsc
        let cabal = case buildType of
                BuildConfig.Library       -> CabalGen.genLibrary    name version ghcOptions allLibs hsc
                BuildConfig.Executable {} -> CabalGen.genExecutable name version ghcOptions allLibs
        CabalStore.run cabal $ UniPath.append (name ++ cabalExt) tmpDir
        CabalInstall.run cfg tmpDir cabalFlags
        case buildType of
            BuildConfig.Executable outputPath -> copyExecutable tmpDir name outputPath
            BuildConfig.Library               -> return ()
        )


--writeSources :: PassMonadIO s m => UniPath -> [Source] -> Pass.Result m ()
writeSources outputPath sources = mapM_ (writeSource outputPath) sources


--writeSource :: PassMonadIO s m => UniPath -> Source -> Pass.Result m ()
writeSource outputPath source = FileWriter.run path hsExt source where
    path = UniPath.append srcFolder outputPath


--copyExecutable :: PassMonadIO s m => UniPath -> String -> UniPath -> Pass.Result m ()
copyExecutable location name outputPath = liftIO $ do
    let execName   = Platform.dependent name (name ++ ".exe") name
        executable = UniPath.append ("dist/build/" ++ name ++ "/" ++ execName) location
    Directory.copyFile executable outputPath


--parseFile :: UniPath -> UniPath -> (MonadIO m => Pass.ResultT m (ASTModule.Module, SourceMap))
parseFile rootPath filePath = do
    logger debug $ "Compiling file '" ++ UniPath.toUnixString filePath ++ "'"
    source <- hoistEither =<< FileReader.run rootPath filePath
    ast    <- hoistEither =<< TxtParser.run source
    return ast


--parseGraph :: PassMonad s m => Diagnostics -> DefManager -> (Definition.ID, Definition) -> Pass.Result m ASTModule.Module
--parseGraph diag defManager def = do
--    logger debug "Compiling graph"
--    let tmpFixed_defManager = DequalifyCalls.run defManager
--    Diagnostics.printDM tmpFixed_defManager diag
--    ast <- GraphParser.run tmpFixed_defManager def
--    return ast
