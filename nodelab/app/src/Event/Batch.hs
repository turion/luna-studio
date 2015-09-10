module Event.Batch where

import           Utils.PreludePlus

import           Batch.Project
import           Batch.Library
import           Batch.Breadcrumbs
import           Batch.Value
import           Object.Node
import           Data.Text.Lazy    (Text)
import qualified Generated.Proto.Dep.Graphview.GraphView as GraphView

data Event = ProjectsList [Project]
           | ProjectCreated Project
           | LibrariesList [Library]
           | LibraryCreated Library
           | ASTElementExists
           | ASTElementDoesNotExist
           | WorkspaceCreated Breadcrumbs
           | NodeAdded Node
           | NodesConnected
           | GraphViewFetched GraphView.GraphView
           | ValueUpdate Int Value
           | CodeUpdate Text
           | RunFinished
           | UnknownEvent String
           | ParseError String
           deriving (Eq, Show)

instance PrettyPrinter Event where
    display = show
