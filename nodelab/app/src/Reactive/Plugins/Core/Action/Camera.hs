{-# LANGUAGE NamedFieldPuns #-}

module Reactive.Plugins.Core.Action.Camera where

import           Utils.PreludePlus
import           Utils.Vector

import qualified JS.Camera             as JS
import           Event.Event             (Event(Keyboard, Mouse))
import           Event.Keyboard          (KeyMods(..), ctrl)
import qualified Event.Keyboard        as Keyboard
import           Event.Mouse             (MouseButton(..))
import qualified Event.Mouse           as Mouse
import           Reactive.State.Camera   (DragHistory(..))
import qualified Reactive.State.Camera as Camera
import qualified Reactive.State.Graph  as Graph
import qualified Reactive.State.Global as Global

import Reactive.Commands.Command (Command, ioCommand, execCommand, performIO)
import           Empire.API.Data.Node (Node)
import qualified Empire.API.Data.Node as Node


toAction :: Event -> Maybe (Command Global.State ())
toAction (Keyboard _ (Keyboard.Event Keyboard.Press '0' KeyMods {_ctrl = True})) = Just $ autoZoom >> (zoom Global.camera syncCamera)
toAction evt = (zoom Global.camera) <$> (>> syncCamera) <$> toAction' evt

toAction' :: Event -> Maybe (Command Camera.State ())
toAction' (Mouse _ (Mouse.Event evt pos RightButton  _ _)) = Just $ zoomDrag evt pos
toAction' (Mouse _ (Mouse.Event evt pos MiddleButton _ _)) = Just $ panDrag  evt pos

toAction' (Mouse _ (Mouse.Event (Mouse.Wheel delta) pos _ KeyMods {_ctrl = False} _)) = Just $ panCamera delta
toAction' (Mouse _ (Mouse.Event (Mouse.Wheel delta) pos _ KeyMods {_ctrl = True} _))  = Just $ wheelZoom pos delta

toAction' (Keyboard _ (Keyboard.Event Keyboard.Press char _)) = case char of
    '='   -> Just $ zoomIn
    '+'   -> Just $ zoomIn
    '-'   -> Just $ zoomOut
    '0'   -> Just $ resetZoom
    _     -> Nothing

toAction' (Keyboard _ (Keyboard.Event Keyboard.Down char KeyMods { _ctrl = True })) = case char of
    '\37' -> Just panLeft
    '\39' -> Just panRight
    '\38' -> Just panUp
    '\40' -> Just panDown
    _     -> Nothing
toAction' _ = Nothing

minCamFactor   =   0.2
maxCamFactor   =   8.0
dragZoomSpeed  = 512.0
wheelZoomSpeed =  64.0
panStep        =  50.0
zoomFactorStep =   1.1

restrictCamFactor = min maxCamFactor . max minCamFactor

panCamera :: Vector2 Double -> Command Camera.State ()
panCamera delta = do
    camFactor <- use $ Camera.camera . Camera.factor
    Camera.camera . Camera.pan += ((/ camFactor) <$> delta)

panLeft  = panCamera $ Vector2 (-panStep)         0
panRight = panCamera $ Vector2   panStep          0
panUp    = panCamera $ Vector2        0   (-panStep)
panDown  = panCamera $ Vector2        0     panStep

setZoom :: Double -> Command Camera.State ()
setZoom newFactor = Camera.camera . Camera.factor .= (restrictCamFactor newFactor)

resetZoom :: Command Camera.State ()
resetZoom = Camera.camera . Camera.factor .= 1.0

autoZoom :: Command Global.State ()
autoZoom = do
    nodes             <- use $ Global.graph  . Graph.nodes
    screenSize'       <- use $ Global.camera . Camera.camera . Camera.screenSize

    zoom Global.camera $ setZoom 1.0
    Global.camera . Camera.camera . Camera.pan    .= Vector2 0.0 0.0

    when (length nodes > 0) $ do
        let padding        = Vector2 80.0 80.0
            screenSize     = fromIntegral <$> screenSize'
            minXY          = -padding + (Vector2 (minimum $ (^. Node.position . _1) <$> nodes) (minimum $ (^. Node.position . _2) <$> nodes))
            maxXY          =  padding + (Vector2 (maximum $ (^. Node.position . _1) <$> nodes) (maximum $ (^. Node.position . _2) <$> nodes))
            spanXY         = maxXY - minXY
            zoomFactorXY   = Vector2 (screenSize ^. x / spanXY ^. x) (screenSize ^. y / spanXY ^. y)
            zoomFactor     = min (zoomFactorXY ^. x) (zoomFactorXY ^. y)
            zoomPan        = minXY + ((/2.0) <$> spanXY)

        zoom Global.camera $ setZoom zoomFactor
        Global.camera . Camera.camera . Camera.pan    .= zoomPan

zoomIn :: Command Camera.State ()
zoomIn = do
    factor <- use $ Camera.camera . Camera.factor
    setZoom $ factor * zoomFactorStep

zoomOut :: Command Camera.State ()
zoomOut = do
    factor <- use $ Camera.camera . Camera.factor
    setZoom $ factor / zoomFactorStep

wheelZoom :: Vector2 Int -> Vector2 Double -> Command Camera.State ()
wheelZoom pos delta = do
    camera         <- use $ Camera.camera
    let delta'      = (- delta ^. x - delta ^. y) / wheelZoomSpeed
        workspace   = Camera.screenToWorkspace camera pos
    fixedPointZoom pos workspace delta'

fixedPointZoom :: Vector2 Int -> Vector2 Double -> Double -> Command Camera.State ()
fixedPointZoom fpScreen fpWorkspace delta = do
    oldFactor           <- use $ Camera.camera . Camera.factor

    let newFactor        = oldFactor * (1.0 + delta)
    setZoom newFactor

    oldCamera           <- use $ Camera.camera
    let nonPannedCamera  = oldCamera & Camera.factor .~ (restrictCamFactor newFactor)
                                     & Camera.pan    .~ Vector2 0.0 0.0
        newWorkspace     = Camera.screenToWorkspace nonPannedCamera fpScreen
        newPan           = -newWorkspace + fpWorkspace

    Camera.camera . Camera.pan .= newPan

panDrag :: Mouse.Type -> Vector2 Int -> Command Camera.State ()
panDrag Mouse.Pressed pos = do
    Camera.history ?= PanDragHistory pos

panDrag Mouse.Moved   pos = do
    history <- use $ Camera.history
    case history of
        Just (PanDragHistory prev) -> do
            Camera.history ?= PanDragHistory pos
            panCamera $ fromIntegral <$> prev - pos
        _                          -> return ()

panDrag Mouse.Released _ = do
    Camera.history .= Nothing

panDrag _ _ = return ()

zoomDrag :: Mouse.Type -> Vector2 Int -> Command Camera.State ()
zoomDrag Mouse.Pressed screenPos = do
    camera           <- use $ Camera.camera
    let workspacePos  = Camera.screenToWorkspace camera screenPos
    Camera.history   ?= ZoomDragHistory screenPos screenPos workspacePos

zoomDrag Mouse.Moved   pos = do
    history <- use $ Camera.history
    case history of
        Just (ZoomDragHistory prev fpScreen fpWorkspace) -> do
            Camera.history ?= ZoomDragHistory pos fpScreen fpWorkspace
            let deltaV = fromIntegral <$> (prev - pos)
                delta  = (-deltaV ^. x + deltaV ^. y) / dragZoomSpeed
            fixedPointZoom fpScreen fpWorkspace delta
        _                           -> return ()

zoomDrag Mouse.Released _ = do
    Camera.history .= Nothing

zoomDrag _ _ = return ()

syncCamera :: Command Camera.State ()
syncCamera = do
    cPan            <- use $ Camera.camera . Camera.pan
    cFactor         <- use $ Camera.camera . Camera.factor
    screenSize      <- use $ Camera.camera . Camera.screenSize
    let hScreen      = (/ 2.0) . fromIntegral <$> screenSize
        camLeft      = appX cameraLeft
        camRight     = appX cameraRight
        camTop       = appY cameraTop
        camBottom    = appY cameraBottom
        hX           = appX htmlX
        hY           = appY htmlY
        appX      f  = f cFactor (cPan ^. x) (hScreen ^. x)
        appY      f  = f cFactor (cPan ^. y) (hScreen ^. y)
    performIO $ do
        JS.updateCamera cFactor camLeft camRight camTop camBottom
        JS.updateCameraHUD 0.0 (fromIntegral $ screenSize ^. x) 0.0 (fromIntegral $ screenSize ^. y)
        JS.updateHtmCanvasPanPos hX hY cFactor
        JS.updateProjectionMatrix
        JS.updateHUDProjectionMatrix



cameraLeft, cameraRight, cameraTop, cameraBottom, htmlX, htmlY :: Double -> Double -> Double -> Double
cameraLeft   camFactor camPanX halfScreenX = -halfScreenX / camFactor + camPanX
cameraRight  camFactor camPanX halfScreenX =  halfScreenX / camFactor + camPanX
cameraTop    camFactor camPanY halfScreenY = -halfScreenY / camFactor + camPanY
cameraBottom camFactor camPanY halfScreenY =  halfScreenY / camFactor + camPanY
htmlX        camFactor camPanX halfScreenX =  halfScreenX - camPanX * camFactor
htmlY        camFactor camPanY halfScreenY =  halfScreenY - camPanY * camFactor

