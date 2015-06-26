module Reactive.Plugins.Core.Network where

import           Control.Applicative
import           Control.Monad              ( when )
import           Control.Lens
import           Data.Default
import           Data.Char                  ( chr )
import           Data.Monoid                ( (<>) )
import           Data.Maybe                 ( isJust, fromJust, catMaybes )
import           Data.Dynamic
import           Debug.Trace                ( trace )

import           Reactive.Banana
import           Reactive.Banana.Frameworks ( AddHandler(..)
                                            , Frameworks
                                            , liftIO
                                            , fromAddHandler
                                            , reactimate
                                            , reactimate'
                                            , actuate
                                            , initial
                                            , changes
                                            )

import           Reactive.Banana.Utils
import           Reactive.Handlers
import           JS.Bindings
import           Object.Object
import           Object.Dynamic             ( unpackDynamic )
import           Object.Node                ( Node(..) )
import qualified Object.Node    as Node
import qualified Event.Event    as Event
import qualified Event.Keyboard as Keyboard ( KeyMods(..), Event(..) )
import           Event.Mouse                ( WithObjects(..) )
import qualified Event.Mouse    as Mouse
import           Utils.PrettyPrinter
import qualified Reactive.Plugins.Core.Action.Graph as Node


instance Monoid (Event t a) where
    mempty  = never
    mappend = union

infixr 6 <+>
(<+>) = union

makeNetworkDescription :: forall t. Frameworks t => Moment t ()
makeNetworkDescription = do
    mouseDownE    <- fromAddHandler mouseDownHandler
    mouseUpE      <- fromAddHandler mouseUpHandler
    mouseMovedE   <- fromAddHandler mouseMovedHandler
    keyPressedE   <- fromAddHandler keyPressedHandler

    let
        -- clicksCountB       = accumB 0 ((+ 1) <$ mouseClickedE)
        lastKeyB                   = stepper Nothing $ Just <$> keyPressedE

        mouseNodeDownE, mouseNodeUpE, mouseNodeMovedE :: Event t (WithObjects Node)
        mouseNodeDownE             = unpackDynamic <$> mouseDownE
        mouseNodeUpE               = unpackDynamic <$> mouseUpE
        mouseNodeMovedE            = unpackDynamic <$> mouseMovedE

        -- mouseE                     = mouseDownE <+> mouseUpE <+> mouseMovedE
        mouseNodeE                 = mouseNodeDownE <+> mouseNodeUpE <+> mouseNodeMovedE

        mouseNodeSelectActionsE    = filterJust $ Node.mouseToSelectAction    <$> mouseNodeE
        mouseNodeDragActionsE      = filterJust $ Node.mouseToDragAction      <$> mouseNodeE
        keyboardNodeActionsE       = filterJust $ Node.keyboardToAction       <$> keyPressedE

        allNodeActionsE            = mouseNodeSelectActionsE <+> mouseNodeDragActionsE <+> keyboardNodeActionsE

        -- mouseNodeReactionB         = accumB def $ Node.accumActionState <$> allNodeActionsE
        mouseNodeReactionE         = accumE def $ Node.accumActionState <$> allNodeActionsE


        -- logClicksB  = ("Clk " <>) . show <$> clicksCountB
        -- logLastKeyB = (""  <>) . display <$> lastKeyB
        -- logMouseB   = (" " <>) . display <$> mouseNodeActionB
        -- logMouseAB  = (" " <>) . display <$> allNodeActionsE
        -- logMouseRB  = (" " <>) . display <$> mouseNodeReactionB
        -- logB        = logLastKeyB <<*>> logMouseB <<*>> logMouseRB
        -- logB        = logLastKeyB -- <<*>> logMouseRB


      -- ng = NodeGraph newSelectionObjE

    -- Render the initial view
    -- initial logB >>= liftIO . logAs ""
    -- logF <- changes logB
    -- reactimate' $ (fmap $ logAs "") <$> logF

    -- reactimate $ (logAs "ll:") <$> (display <$> mouseNodeE)



    -- mouseNodeReactionF <- changes mouseNodeReactionB
    -- reactimate' $ (fmap Node.updateNodes) <$> mouseNodeReactionF
    reactimate $ Node.updateNodesUI <$> mouseNodeReactionE
    reactimate $ (logAs "") <$> (display <$> mouseNodeReactionE)


    return ()