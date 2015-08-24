{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FunctionalDependencies #-}

module ThreeJS.Types where

import           Utils.PreludePlus
import qualified GHCJS.Prim.Internal.Build as Build

import           GHCJS.Foreign
import           GHCJS.Types      ( JSRef )
import           GHCJS.DOM.EventTargetClosures (EventName, unsafeEventName)
import           Data.JSString.Text ( lazyTextFromJSString, lazyTextToJSString )
import           Data.JSString ( JSString )
import qualified Data.JSString as JSString

import           JavaScript.Array ( JSArray )
import qualified JavaScript.Array as JSArray

import qualified Data.Text.Lazy as Text
import           Data.Text.Lazy (Text)
import qualified JavaScript.Object as JSObject

import Unsafe.Coerce
import System.IO.Unsafe
import Debug.Trace

import GHCJS.Prim
import ThreeJS.Converters
import ThreeJS.Registry

class Container a where
    add    :: (Object b) => a -> b -> IO ()
    remove :: (Object b) => a -> b -> IO ()

data MeshJS
type Mesh  = JSRef MeshJS
data Group = Group {unGroup :: Mesh}
data Scene = Scene (JSRef Scene)



class Object a where mesh :: a -> IO Mesh

instance Object Mesh  where mesh a = return a
instance Object Group where mesh (Group a) = return a

data JSVector2
data JSVector3
data JSVector4

foreign import javascript unsafe "new THREE.Vector2($1, $2)"
    buildVector2 :: Double -> Double -> IO (JSRef JSVector2)
foreign import javascript unsafe "new THREE.Vector3($1, $2, $3)"
    buildVector3 :: Double -> Double -> Double -> IO (JSRef JSVector3)
foreign import javascript unsafe "new THREE.Vector4($1, $2, $3, $4)"
    buildVector4 :: Double -> Double -> Double -> Double -> IO (JSRef JSVector4)

foreign import javascript unsafe "$1.x = $2" setX :: JSRef a -> Double -> IO ()
foreign import javascript unsafe "$1.y = $2" setY :: JSRef a -> Double -> IO ()
foreign import javascript unsafe "$1.z = $2" setZ :: JSRef a -> Double -> IO ()
foreign import javascript unsafe "$1.a = $2" setA :: JSRef a -> Double -> IO ()


class Geometry a
class IsMaterial a where material :: a -> Material

data MaterialJS
type Material = JSRef MaterialJS

data SceneType = HUD | Workspace deriving (Show, Eq, Enum)