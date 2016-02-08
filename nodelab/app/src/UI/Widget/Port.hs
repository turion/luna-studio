{-# LANGUAGE OverloadedStrings #-}

module UI.Widget.Port where

import           Utils.PreludePlus
import           Utils.CtxDynamic              (toCtxDynamic)
import           Utils.Vector

import           Data.JSString.Text            (lazyTextFromJSString, lazyTextToJSString)
import           GHCJS.DOM.Element             (Element)
import           GHCJS.Marshal.Pure            (PFromJSVal (..), PToJSVal (..))
import           GHCJS.Types                   (JSString, JSVal)

import           Event.Mouse                   (MouseButton (..))
import           Object.UITypes
import           Object.Widget
import qualified Object.Widget.Port            as Model

import           Reactive.Commands.Command     (Command, ioCommand, performIO)
import qualified Reactive.State.Global         as Global
import qualified Reactive.State.UIRegistry     as UIRegistry

import qualified UI.Registry                   as UIR
import           UI.Widget                     (UIContainer (..), UIWidget (..))
import           UI.Widget                     (GenericWidget (..))
import qualified UI.Widget                     as Widget

newtype Port = Port { unPort :: JSVal } deriving (PToJSVal, PFromJSVal)

instance UIWidget Port

foreign import javascript safe "new Port($1)"     create'  :: WidgetId         -> IO Port
foreign import javascript safe "$1.setAngle($2, $3)"  setAngle :: Port -> Double  -> Int -> IO ()
foreign import javascript safe "$1.setColor($2)"  setColor :: Port -> Int      -> IO ()

create :: WidgetId -> Model.Port -> IO Port
create id model = do
    port <- create' id
    setAngle port (model ^. Model.angle) (-id)
    setColor port $ model ^. Model.color
    return port

instance UIDisplayObject Model.Port where
    createUI parentId id model = do
        widget  <- create id model
        parent  <- UIR.lookup parentId :: IO GenericWidget
        UIR.register id widget
        Widget.add widget  parent

    updateUI id old model = do
        port <- UIR.lookup id :: IO Port
        setAngle port (model ^. Model.angle) id
        setColor port $ model ^. Model.color

widgetHandlers :: UIHandlers Global.State
widgetHandlers = def

instance CompositeWidget Model.Port
instance ResizableWidget Model.Port
