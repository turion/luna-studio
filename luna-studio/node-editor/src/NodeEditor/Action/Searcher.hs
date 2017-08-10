{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE OverloadedStrings #-}
module NodeEditor.Action.Searcher where

import           Common.Action.Command                      (Command)
import           Common.Prelude
import qualified Data.Text                                  as Text
import qualified JS.GoogleAnalytics                         as GA
import qualified JS.Searcher                                as Searcher
import           Luna.Syntax.Text.Lexer                     (runGUILexer)
import           LunaStudio.Data.Geometry                   (snap)
import           LunaStudio.Data.Matrix                     (invertedTranslationMatrix, translationMatrix)
import           LunaStudio.Data.NodeLoc                    (NodeLoc, NodePath)
import qualified LunaStudio.Data.NodeLoc                    as NodeLoc
import           LunaStudio.Data.PortRef                    (OutPortRef (OutPortRef))
import           LunaStudio.Data.ScreenPosition             (move, x, y)
import           LunaStudio.Data.Size                       (height, width)
import           LunaStudio.Data.TypeRep                    (TypeRep (TCons))
import           LunaStudio.Data.Vector2                    (Vector2 (Vector2))
import           NodeEditor.Action.Basic                    (createNode, localClearSearcherHints, localUpdateSearcherHints, renameNode,
                                                             renamePort, setNodeExpression)
import           NodeEditor.Action.Basic                    (modifyCamera)
import           NodeEditor.Action.State.Action             (beginActionWithKey, continueActionWithKey, removeActionFromState,
                                                             updateActionWithKey)
import           NodeEditor.Action.State.App                (renderIfNeeded)
import           NodeEditor.Action.State.NodeEditor         (findSuccessorPosition, getExpressionNode, getPort,
                                                             getSearcher, getSelectedNodes, getSelectedNodes, modifyNodeEditor,
                                                             modifySearcher)
import           NodeEditor.Action.State.Scene              (translateToWorkspace)
import           NodeEditor.Action.State.Scene              (getScreenSize, translateToScreen)
import           NodeEditor.Action.UUID                     (getUUID)
import           NodeEditor.Event.Event                     (Event (Shortcut))
import qualified NodeEditor.Event.Shortcut                  as Shortcut
import           NodeEditor.React.Model.Constants           (nameEditWidth, searcherHeight, searcherWidth)
import qualified NodeEditor.React.Model.Node.ExpressionNode as ExpressionNode
import qualified NodeEditor.React.Model.NodeEditor          as NodeEditor
import qualified NodeEditor.React.Model.Port                as Port
import qualified NodeEditor.React.Model.Searcher            as Searcher
import qualified NodeEditor.React.View.App                  as App
import           NodeEditor.State.Action                    (Action (begin, continue, end, update), Searcher (Searcher), searcherAction)
import           NodeEditor.State.Global                    (State)
import qualified NodeEditor.State.Global                    as Global
import qualified NodeEditor.State.UI                        as UI
import           Text.Read                                  (readMaybe)


instance Action (Command State) Searcher where
    begin    = beginActionWithKey    searcherAction
    continue = continueActionWithKey searcherAction
    update   = updateActionWithKey   searcherAction
    end      = close


editExpression :: NodeLoc -> Command State ()
editExpression nodeLoc = do
    let getClassName n = case n ^? ExpressionNode.inPortAt [Port.Self] . Port.valueType of
            Just (TCons cn _) -> Just $ convert cn
            _                 -> Nothing
    mayN <- getExpressionNode nodeLoc
    withJust mayN $ \n -> do
        openWith (n ^. ExpressionNode.code) $ Searcher.Node nodeLoc (Searcher.NodeModeInfo (getClassName n) def def) def

editName :: NodeLoc -> Command State ()
editName nodeLoc = do
    mayN <- getExpressionNode nodeLoc
    withJust mayN $ \n -> do
        openWith (maybe "" id $ n ^. ExpressionNode.name) $ Searcher.NodeName nodeLoc def

editPortName :: OutPortRef -> Command State ()
editPortName portRef = do
    mayP <- getPort portRef
    withJust mayP $ \p -> do
        openWith (p ^. Port.name) $ Searcher.PortName portRef def

open :: Command State ()
open = do
    (className, nn) <- getSelectedNodes >>= \case
        [n] -> do
            pos <- findSuccessorPosition n
            let mayP        = listToMaybe $ ExpressionNode.outPortsList n
                className   = case view Port.valueType <$> mayP of
                    Just (TCons cn _) -> Just $ convert cn
                    _                 -> Nothing
                predPortRef = OutPortRef (n ^. ExpressionNode.nodeLoc) . view Port.portId <$> mayP
            return $ (className, Searcher.NewNode (snap pos) predPortRef)
        _   -> do
            pos <- translateToWorkspace =<< use (Global.ui . UI.mousePos)
            return $ (def, Searcher.NewNode (snap pos) def)
    nl <- convert . ((def :: NodePath), ) <$> getUUID
    openWith "" $ Searcher.Node nl (Searcher.NodeModeInfo className (Just nn) def) def

openWith :: Text -> Searcher.Mode -> Command State ()
openWith input mode = do
    mayNodePosAndTop <- case mode of
        Searcher.Command  {} -> return Nothing
        Searcher.PortName {} -> return Nothing
        Searcher.NodeName nl _ -> do
            maySearcherBottom <- mapM translateToScreen . fmap (view ExpressionNode.topPosition) =<< getExpressionNode nl
            let maySearcherTop = move (Vector2 0 (-2 * searcherHeight)) <$> maySearcherBottom
            return $ (,) <$> maySearcherBottom <*> maySearcherTop
        Searcher.Node nl (Searcher.NodeModeInfo _ mayNewNodeData _) _ -> do
            maySearcherBottom <- mapM translateToScreen =<< case mayNewNodeData of
                Nothing -> (view ExpressionNode.topPosition) `fmap2` getExpressionNode nl
                Just (Searcher.NewNode pos _) -> return . Just $ ExpressionNode.toNodeTopPosition pos
            let maySearcherTop = move (Vector2 0 (-11 * searcherHeight)) <$> maySearcherBottom
            return $ (,) <$> maySearcherBottom <*> maySearcherTop
    mayScreenSize <- getScreenSize
    withJust ((,) <$> mayNodePosAndTop <*> mayScreenSize) $ \((searcherBottom, searcherTop), screenSize) -> do
        let distToSearcherEdge = case mode of
                Searcher.NodeName {} -> nameEditWidth / 2
                Searcher.Node     {} -> searcherWidth / 2
                _                    -> 0
        let overRightEdge = searcherTop ^. x + distToSearcherEdge > screenSize ^. width
            overLeftEdge  = searcherTop ^. x - distToSearcherEdge < 0
            overTopEdge   = searcherTop ^. y < 0
            xShift = if searcherWidth > screenSize ^. width then Nothing
                else if overRightEdge then Just $ searcherTop ^. x + distToSearcherEdge - screenSize ^. width
                else if overLeftEdge  then Just $ searcherTop ^. x - distToSearcherEdge
                else Nothing
            yShift = if searcherBottom ^. y - searcherTop ^. y > screenSize ^. height then Just $ searcherBottom ^. y - screenSize ^. height
                else if overTopEdge then Just $ searcherTop ^. y
                else Nothing
            mayDelta = if isNothing xShift && isNothing yShift then Nothing else Just $ Vector2 (fromMaybe def xShift) (fromMaybe def yShift)
        withJust mayDelta $ \delta ->
            modifyCamera (invertedTranslationMatrix delta) (translationMatrix delta)
    -- print mayNodePos
    -- getScreenSize >>= print
    let action   = Searcher
        inputLen = Text.length input
    begin action
    GA.sendEvent GA.NodeSearcher
    modifyNodeEditor $ NodeEditor.searcher ?= Searcher.Searcher 0 mode def False False
    modifyInput input inputLen inputLen action
    renderIfNeeded
    Searcher.focus

updateInput :: Text -> Int -> Int -> Searcher -> Command State ()
updateInput input selectionStart selectionEnd action = do
    let inputStream = runGUILexer $ convert input
        newInput    = if selectionStart /= selectionEnd
                          then Searcher.Raw input
                      else if Text.null input
                          then Searcher.Divided $ Searcher.DividedInput def def def
                          else Searcher.fromStream input inputStream selectionStart
    modifySearcher $ Searcher.input .= newInput
    m <- fmap2 (view Searcher.mode) $ getSearcher
    if      isNothing $ newInput ^? Searcher._Divided then clearHints action
    else if isJust $ maybe def (^? Searcher._Node) m  then do
        case Searcher.findLambdaArgsAndEndOfLambdaArgs inputStream of
            Nothing             -> do
                modifySearcher $ Searcher.mode %= Searcher.updateNodeArgs []
                updateHints action
            Just (args, endPos) -> do
                modifySearcher $ Searcher.mode %= Searcher.updateNodeArgs (convert args)
                if selectionStart < endPos then clearHints action else do updateHints action
    else updateHints action

modifyInput :: Text -> Int -> Int -> Searcher -> Command State ()
modifyInput input selectionStart selectionEnd action = do
    updateInput input selectionStart selectionEnd action
    modifySearcher $ Searcher.replaceInput .= True
    renderIfNeeded
    Searcher.setSelection selectionStart selectionEnd
    modifySearcher $ Searcher.replaceInput .= False

updateHints :: Searcher -> Command State ()
updateHints _ = localUpdateSearcherHints

clearHints :: Searcher -> Command State ()
clearHints _ = localClearSearcherHints

handleTabPressed :: Searcher -> Command State ()
handleTabPressed action = withJustM getSearcher $ \s ->
    if Text.null (s ^. Searcher.inputText) && s ^. Searcher.selected == 0
        then close action
        else void $ updateInputWithSelectedHint action

updateInputWithSelectedHint :: Searcher -> Command State Bool
updateInputWithSelectedHint action = getSearcher >>= maybe (return False) updateWithSearcher where
    updateWithSearcher s = if s ^. Searcher.selected == 0 then return True else do
        let mayExpr         = s ^. Searcher.selectedExpression
            mayDividedInput = s ^? Searcher.input . Searcher._Divided
        withJust ((,) <$> mayExpr <*> mayDividedInput) $ \(expr, divInput) -> do
            let divInput' = divInput & Searcher.query .~ expr'
                lastChar = divInput ^? Searcher.suffix . ix 0
                expr'    = if lastChar == Just ' '
                           || lastChar == Just ')'
                           then expr else expr <> " "
                newInput = Searcher.toText $ Searcher.Divided divInput'
                caretPos = Text.length (divInput' ^. Searcher.prefix) + Text.length expr'
            modifyInput newInput caretPos caretPos action
        return $ isJust mayExpr && isJust mayDividedInput

accept :: (Event -> IO ()) -> Searcher -> Command State ()
accept scheduleEvent action = whenM (updateInputWithSelectedHint action) $
    withJustM getSearcher $ \searcher -> do
        let inputText = searcher ^. Searcher.inputText
        case searcher ^. Searcher.mode of
            Searcher.Command                                           _ -> execCommand action scheduleEvent $ convert inputText
            Searcher.Node     nl (Searcher.NodeModeInfo _ (Just nn) _) _ -> createNode (nl ^. NodeLoc.path) (nn ^. Searcher.position) inputText False >> close action
            Searcher.Node     nl _                                     _ -> setNodeExpression nl inputText >> close action
            Searcher.NodeName nl                                       _ -> renameNode nl inputText >> close action
            Searcher.PortName portRef                                  _ -> renamePort portRef inputText >> close action

execCommand :: Searcher -> (Event -> IO ()) -> String -> Command State ()
execCommand action scheduleEvent inputText = case readMaybe inputText of
    Just command -> do
        liftIO $ scheduleEvent $ Shortcut $ Shortcut.Event command def
        close action
    Nothing -> case readMaybe inputText of
        Just Searcher.AddNode -> modifySearcher $ do
            Searcher.selected .= def
            Searcher.mode     %= (\(Searcher.Node nl nmi _) -> Searcher.Node nl nmi def)
            Searcher.input    .= Searcher.Raw def
            Searcher.rollbackReady .= False
        Nothing -> return ()

close :: Searcher -> Command State ()
close _ = do
    modifyNodeEditor $ NodeEditor.searcher .= Nothing
    removeActionFromState searcherAction
    App.focus

selectNextHint :: Searcher -> Command State ()
selectNextHint _ = modifySearcher $ do
    hintsLen <- use Searcher.resultsLength
    Searcher.selected %= \p -> (p + 1) `mod` (hintsLen + 1)

selectPreviousHint :: Searcher -> Command State ()
selectPreviousHint _ = modifySearcher $ do
    hintsLen <- use Searcher.resultsLength
    Searcher.selected %= \p -> (p - 1) `mod` (hintsLen + 1)

selectHint :: Int -> Searcher -> Command State Bool
selectHint i _ = do
    mayHintsLen <- fmap2 (view Searcher.resultsLength) getSearcher
    case mayHintsLen of
        Nothing       -> return False
        Just hintsLen -> if i < 0 || i > hintsLen then return False else do
            modifySearcher $ Searcher.selected .= i
            return True

acceptWithHint :: (Event -> IO ()) -> Int -> Searcher -> Command State ()
acceptWithHint scheduleEvent hintNum' action = let hintNum = (hintNum' - 1) `mod` 10 in
    withJustM (view Searcher.selected `fmap2` getSearcher) $ \selected ->
        whenM (selectHint (max selected 1 + hintNum) action) $ accept scheduleEvent action

updateInputWithHint :: Int -> Searcher -> Command State ()
updateInputWithHint hintNum' action = let hintNum = (hintNum' - 1) `mod` 10 in
    withJustM (view Searcher.selected `fmap2` getSearcher) $ \selected ->
        whenM (selectHint (max selected 1 + hintNum) action) $
            updateInputWithSelectedHint action

-- tryRollback :: Searcher -> Command State ()
-- tryRollback _ = do
--     withJustM getSearcher $ \searcher -> do
--        when (Text.null (searcher ^. Searcher.inputText)
--          && (searcher ^. Searcher.isNode)
--          && (searcher ^. Searcher.rollbackReady)) $
--             modifySearcher $ do
--                 Searcher.rollbackReady .= False
--                 Searcher.selected      .= def
--                 Searcher.mode          .= Searcher.Command def
--                 Searcher.input         .= Searcher.Raw def
--
-- enableRollback :: Searcher -> Command State ()
-- enableRollback _ = modifySearcher $
--     Searcher.rollbackReady .= True
