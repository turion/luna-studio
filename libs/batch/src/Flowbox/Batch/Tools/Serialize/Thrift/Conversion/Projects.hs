---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, TypeSynonymInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Flowbox.Batch.Tools.Serialize.Thrift.Conversion.Projects where


import           Data.Text.Lazy                                              (pack, unpack)

import qualified Projects_Types                                            as TProjects
import qualified Flowbox.Batch.Project.Project                             as Project
import           Flowbox.Batch.Project.Project                               (Project(..))
import           Flowbox.Control.Error
import           Flowbox.Luna.Lib.LibManager                                 (LibManager)
import           Flowbox.Luna.Tools.Serialize.Thrift.Conversion.Defs         ()
import qualified Flowbox.System.UniPath                                    as UniPath
import           Flowbox.Tools.Conversion



instance Convert (Project.ID, Project) (TProjects.Project, LibManager) where
    encode (projectID, project) = (tproject, alibs) where
        Project aname apath alibs aattrs = project
        tname      = pack aname
        tpath      = pack $ UniPath.toUnixString apath
        tattrs     = encode aattrs
        tprojectID = itoi32 projectID
        tproject   = TProjects.Project (Just tname) (Just tpath) (Just tattrs) (Just tprojectID)
    decode (TProjects.Project mtname mtpath mtattrs mtprojectID, alibs) = do
        tname       <- mtname  <?> "Failed to decode Project: `name` field is missing"
        tpath       <- mtpath  <?> "Failed to decode Project: `path` field is missing"
        tattrs      <- mtattrs <?> "Failed to decode Project: `attrs` field is missing"
        aattrs      <- decode tattrs
        tprojectID  <- mtprojectID <?> "Failed to decode Project: `projectID` field is missing"
        let aname     = unpack tname
            apath     = UniPath.fromUnixString $ unpack tpath
            projectID = i32toi tprojectID
            project   = Project aname apath alibs aattrs
        return (projectID, project)

