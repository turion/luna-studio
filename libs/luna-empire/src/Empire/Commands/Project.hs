module Empire.Commands.Project where

import           Prologue
import           Control.Monad.State
import           Control.Monad.Error (throwError)
import           Empire.Empire       (Empire, Empire', ProjectManager)
import qualified Empire.Empire       as Empire
import           Empire.Data.Project (Project, ProjectId)
import qualified Empire.Data.Project as Project
import           System.Path         (Path)
import qualified Data.IntMap         as IntMap

insertAtNewId :: Project -> Empire' ProjectManager ProjectId
insertAtNewId project = do
    pm <- get
    let key = if IntMap.null pm then 0 else 1 + (fst . IntMap.findMax $ pm)
    at key ?= project
    return key

createProject :: Maybe String -> Path -> Empire (ProjectId, Project)
createProject name path = do
    let project = Project.make name path
    id <- zoom Empire.projectManager $ insertAtNewId project
    return (id, project)

listProjects :: Empire [(ProjectId, Project)]
listProjects = uses Empire.projectManager IntMap.toList

withProject :: ProjectId -> Empire' Project a -> Empire a
withProject pid cmd = zoom (Empire.projectManager . at pid) $ do
    projectMay <- get
    case projectMay of
        Nothing      -> throwError $ "Project " ++ (show pid) ++ "does not exist."
        Just project -> do
            let result = (_2 %~ Just) <$> Empire.runEmpire project cmd
            Empire.empire $ const result
