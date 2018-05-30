{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE TypeOperators #-}
module Empire.Prelude (module X, nameToString, pathNameToString, stringToName,
                      (<?!>), putLayer, attachLayer, AnyExpr, AnyExprLink,
                      makeWrapped, Expr, SubPass, pattern MarkedExprMap,
                      pattern ASGFunction, pattern Lam, pattern Unify,
                      pattern App, pattern Cons, pattern Grouped, pattern Var,
                      pattern List, pattern Tuple, getAttr, putAttr,
                      source, target, getLayer, type Link, matchExpr,
                      ptrListToList, generalize, replace, makePrisms,
                      type SomeExpr, use, preuse, (?=), (.=), (%=), to, _Just,
                      (?~), pattern Seq, pattern Marked, pattern Blank,
                      pattern Acc, pattern Documented, narrowTerm,
                      pattern Unit, replaceSource, modifyLayer_,
                      type LeftSpacedSpan, pattern LeftSpacedSpan,
                      ociSetToList, pattern IRString, pattern IRNumber,
                      nameToText, type MarkedExprMap, deleteSubtree, substitute,
                      unsafeRelayout, irDelete, link, modifyExprTerm,
                      type ASGFunction, pattern LeftSection, zoom,
                      pattern RightSection, pattern Missing, pattern Marker,
                      type IRSuccs, deepDelete, deepDeleteWithWhitelist,
                      pattern ClsASG, type ClsASG, pattern Metadata, inputs,
                      pattern ImportHub, pattern Import, pattern ImportSrc
                      ) where

import qualified Data.Convert              as Convert
import qualified Data.Typeable as Typeable
import qualified Data.PtrList.Mutable as PtrList
import qualified Data.PtrSet.Mutable as PtrSet
import qualified Data.Graph.Data.Component.Set as PtrSet
-- import qualified Data.Graph.Component.Container as PtrSet
import qualified Data.Text.Span as Span
-- import qualified Data.Graph.Component as Component
import qualified Data.Graph.Component.Node.Class    as Node
import qualified Data.Graph.Data.Layer.Class as Layer
import qualified Data.Graph.Component.Node.Layer as Layer
import qualified Data.Graph.Data.Layer.Layout as Layout
-- import qualified OCI.Pass.Registry as Registry
import qualified Luna.IR as IR
import OCI.IR.Link.Class (type (*-*), Links)
import OCI.IR.Term.Class (Term, Terms)
import qualified Luna.IR.Term.Core as Ast
import qualified Data.Set.Mutable.Class     as Set
import qualified Luna.IR.Term.Literal as Ast
import qualified Luna.IR.Term.Ast.Class as Ast
import Data.Graph.Data.Component.Class (Component)
import qualified Data.Graph.Data.Component.Class as Component
import qualified Data.Graph.Data.Component.List as List (List(..))
import qualified Data.Graph.Component.Edge as Edge
import qualified Data.Graph.Component.Edge.Construction as Construction
import qualified Data.Graph.Traversal.SubComponents as Traversal
import Parser.State.Marker (TermMap(..))
import Luna.Pass (Pass)
import qualified Luna.Pass.Attr as Attr
import Control.Lens ((?=), (.=), (%=), to, makeWrapped, makePrisms, use, preuse,
                     _Just, (?~), zoom)
import Prologue as X hiding (TypeRep, head, tail, init, last, p, r, s, (|>), return, liftIO, fromMaybe, fromJust, when, mapM, mapM_, minimum)
import Control.Monad       as X (return, when, mapM, mapM_, forM)
import Control.Monad.Trans as X (liftIO)
import Data.List           as X (head, tail, init, last, sort, minimum)
import Data.Maybe          as X (fromJust, fromMaybe)

infixr 0 <?!>
(<?!>) :: (Exception e, MonadThrow m) => m (Maybe a) -> e -> m a
m <?!> e = m >>= maybe (throwM e) pure


nameToString :: IR.Name -> String
nameToString = convertTo @String

nameToText :: IR.Name -> Text
nameToText = convert . convertTo @String

-- pathNameToString :: IR.QualName -> String
pathNameToString = error "pathNameToString"

-- stringToName :: String -> IR.Name
stringToName = error "stringToName"

putLayer :: forall layer t layout m. Layer.Writer t layer m => t layout -> Layer.Data layer layout -> m ()
putLayer = Layer.write @layer

getLayer :: forall layer t layout m. Layer.Reader t layer m => t layout -> m (Layer.Data layer layout)
getLayer = Layer.read @layer

modifyLayer_ :: forall layer t layout m. (Layer.Reader t layer m, Layer.Writer t layer m) => t layout -> (Layer.Data layer layout -> Layer.Data layer layout) -> m ()
modifyLayer_ comp f = getLayer @layer comp >>= putLayer @layer comp . f


getTypeDesc_ :: forall a. (KnownType a, Typeable a) => Typeable.TypeRep
getTypeDesc_ = Typeable.typeRep (Proxy @a)

attachLayer :: forall comp layer m. _ => m ()
attachLayer = error "attachLayer" -- Registry.registerPrimLayer @layer @comp

type AnyExpr = Terms
type AnyExprLink = Links
type Expr = Term
type SubPass = Pass
type Link a b = Edge.Edge (a *-* b)
type SomeExpr = IR.SomeTerm
type LeftSpacedSpan a = Span.LeftSpacedSpan
type IRSuccs = IR.Users

pattern LeftSpacedSpan a <- Span.LeftSpacedSpan a where
    LeftSpacedSpan a = Span.LeftSpacedSpan a

type MarkedExprMap = TermMap
pattern MarkedExprMap m <- TermMap m where
    MarkedExprMap m = TermMap m

type ASGFunction = IR.Function
type ClsASG = IR.Record

pattern ASGFunction n as b <- IR.UniTermFunction (Ast.Function n as b)
pattern LeftSection f a <- IR.UniTermSectionLeft (Ast.SectionLeft f a)
pattern RightSection f a <- IR.UniTermSectionRight (Ast.SectionRight f a)
pattern Unit n as b <- IR.UniTermUnit (Ast.Unit n as b)
pattern Unify l r <- IR.UniTermUnify (Ast.Unify l r)
pattern Lam i o <- IR.UniTermLam (Ast.Lam i o)
pattern Missing <- IR.UniTermMissing (Ast.Missing)
pattern App f a <- IR.UniTermApp (Ast.App f a)
pattern Cons n a <- IR.UniTermCons (Ast.Cons n a)
pattern Grouped g <- IR.UniTermGrouped (Ast.Grouped g)
pattern Var n <- IR.UniTermVar (Ast.Var n)
pattern Marked m n <- IR.UniTermMarked (Ast.Marked m n)
pattern Marker  l <- IR.UniTermMarker (Ast.Marker l)
pattern List  l <- IR.UniTermList (Ast.List l)
pattern Tuple t <- IR.UniTermTuple (Ast.Tuple t)
pattern Seq l r <- IR.UniTermSeq (Ast.Seq l r)
pattern Blank <- IR.UniTermBlank (Ast.Blank)
pattern Acc n e <- IR.UniTermAcc (Ast.Acc n e)
pattern Documented doc e <- IR.UniTermDocumented (Ast.Documented doc e)
pattern IRString s <- IR.UniTermRawString (Ast.RawString s)
pattern IRNumber a b c <- IR.UniTermNumber (Ast.Number a b c)
pattern ClsASG a b c d e <- IR.UniTermRecord (Ast.Record a b c d e)
pattern Metadata a <- IR.UniTermMetadata (Ast.Metadata a)
pattern ImportHub a <- IR.UniTermImportHub (Ast.ImportHub a)
pattern Import doc e <- IR.UniTermImp (Ast.Imp doc e)
pattern ImportSrc a <- IR.UniTermImportSource (Ast.ImportSource a)

getAttr :: forall attr m. (Monad m, Attr.Getter attr m) => m attr
putAttr :: forall attr m. (Monad m, Attr.Setter attr m) => attr -> m ()
getAttr = Attr.get @attr
putAttr = Attr.put

source :: (Layer.Reader IR.Link IR.Source m, Coercible (Expr t) (Expr (Layout.Get IR.Source layout)))
       => IR.Link layout -> m (Expr t)
source = \a -> IR.source a >>= \b -> return (coerce b)

target :: (Layer.Reader IR.Link IR.Target m, Coercible (Expr t) (Expr (Layout.Get IR.Target layout)))
       => IR.Link layout -> m (Expr t)
target = \a -> IR.target a >>= \b -> return (coerce b)


matchExpr :: forall t layout m. Layer.Reader t IR.Model m => t layout -> (IR.UniTerm layout -> _) -> m _
matchExpr e f = Layer.read @IR.Model e >>= f

ptrListToList :: (MonadIO m, PtrList.IsPtrList t, PtrList.IsPtr a) => t a -> m [a]
ptrListToList = PtrList.toList

ociSetToList :: (MonadIO m, PtrSet.IsPtr a) => PtrSet.Set c l -> m [a]
ociSetToList = PtrSet.toList . (coerce :: PtrSet.Set c l -> PtrSet.UnmanagedPtrSet a)

generalize :: Coercible a b => a -> b
generalize = coerce

replace :: ( Monad m
           , Layer.Reader (Component Edge.Edges) Edge.Source m
           , Layer.Writer (Component Edge.Edges) Edge.Source m
           , Layer.Reader (Component Node.Nodes) IRSuccs m
           ) => Expr l -> Expr l' -> m ()
replace = error "replace"

irDelete e = return () -- error "delete"

substitute :: ( MonadIO m
              , Layer.Reader (Component Node.Nodes) IRSuccs m
              , Layer.Reader (Component Edge.Edges) Edge.Source m
              , Layer.Writer (Component Edge.Edges) Edge.Source m
              ) => IR.SomeTerm -> IR.SomeTerm -> m ()
substitute new old = do
    succs <- getLayer @IRSuccs old
    list <- Set.toList succs
    mapM_ (replaceSource new) $ map generalize list

unsafeRelayout :: Coercible a b => a -> b
unsafeRelayout = coerce

replaceSource :: ( Monad m
                 , Layer.Reader (Component Edge.Edges) Edge.Source m
                 , Layer.Writer (Component Edge.Edges) Edge.Source m
                 , Layer.Reader (Component Node.Nodes) IRSuccs m
                 , MonadIO m
                 )  => IR.SomeTerm -> Edge.SomeEdge -> m ()
replaceSource newSource link = do
    src <- getLayer @IR.Source link
    srcSuccs <- getLayer @IRSuccs src
    Set.delete srcSuccs $ generalize link
    newSrcSuccs <- getLayer @IRSuccs newSource
    Set.insert newSrcSuccs $ generalize link
    putLayer @IR.Source link $ generalize newSource

narrowTerm :: forall b m a. Monad m => Expr a -> m (Maybe (Expr b))
narrowTerm e = return $ Just (coerce e)

deleteSubtree e = return () -- error "deleteSubtree"
deepDelete = error "deepDelete"
deepDeleteWithWhitelist e set = return () -- error "deepDeleteWithWhitelist"


link :: Construction.Creator m => Term src -> Term tgt -> m (Link src tgt)
link = Construction.new

modifyExprTerm = error "modifyExprTerm"

compListToList :: List.List a -> [Component.Some a]
compListToList List.Nil = []
compListToList (List.Cons a l) = a : compListToList l

inputs :: ( Layer.Reader Node.Node IR.Model m
          , Layer.IsUnwrapped Node.Uni
          , Traversal.SubComponents Edge.Edges m (Node.Uni layout)
          , MonadIO m
          ) => Node.Node layout -> m [Component.Some Edge.Edges]
inputs ref = do
    inp <- compListToList <$> IR.inputs ref
    add <- Layer.read @IR.Model ref >>= \case
        IR.UniTermRecord (IR.Record _ _ _ _ decls) -> do
            links <- PtrList.toList decls
            return $ map coerce links
        _ -> return []
    return $ inp <> add