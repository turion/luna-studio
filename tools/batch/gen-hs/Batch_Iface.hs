{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-----------------------------------------------------------------
-- Autogenerated by Thrift Compiler (0.9.0)                      --
--                                                             --
-- DO NOT EDIT UNLESS YOU ARE SURE YOU KNOW WHAT YOU ARE DOING --
-----------------------------------------------------------------

module Batch_Iface where
import Prelude ( Bool(..), Enum, Double, String, Maybe(..),
                 Eq, Show, Ord,
                 return, length, IO, fromIntegral, fromEnum, toEnum,
                 (.), (&&), (||), (==), (++), ($), (-) )

import Control.Exception
import Data.ByteString.Lazy
import Data.Hashable
import Data.Int
import Data.Text.Lazy ( Text )
import qualified Data.Text.Lazy as TL
import Data.Typeable ( Typeable )
import qualified Data.HashMap.Strict as Map
import qualified Data.HashSet as Set
import qualified Data.Vector as Vector

import Thrift
import Thrift.Types ()

import qualified Attrs_Types
import qualified Defs_Types
import qualified Graph_Types
import qualified Libs_Types
import qualified Types_Types


import Batch_Types

class Batch_Iface a where
  libraries :: a -> IO (Vector.Vector Libs_Types.Library)
  loadLibrary :: a -> Maybe Libs_Types.Library -> IO Libs_Types.Library
  unloadLibrary :: a -> Maybe Libs_Types.Library -> IO ()
  newDefinition :: a -> Maybe Types_Types.Type -> Maybe Attrs_Types.Flags -> Maybe Attrs_Types.Attributes -> IO Defs_Types.NodeDefinition
  addDefinition :: a -> Maybe Defs_Types.NodeDefinition -> Maybe Defs_Types.NodeDefinition -> IO Defs_Types.NodeDefinition
  updateDefinition :: a -> Maybe Defs_Types.NodeDefinition -> IO ()
  removeDefinition :: a -> Maybe Defs_Types.NodeDefinition -> IO ()
  definitionChildren :: a -> Maybe Defs_Types.NodeDefinition -> IO (Vector.Vector Defs_Types.NodeDefinition)
  definitionParent :: a -> Maybe Defs_Types.NodeDefinition -> IO Defs_Types.NodeDefinition
  newTypeModule :: a -> Maybe Text -> IO Types_Types.Type
  newTypeClass :: a -> Maybe Text -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeFunction :: a -> Maybe Text -> Maybe Types_Types.Type -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeUdefined :: a -> IO Types_Types.Type
  newTypeNamed :: a -> Maybe Text -> IO Types_Types.Type
  newTypeVariable :: a -> Maybe Text -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeList :: a -> Maybe Types_Types.Type -> IO Types_Types.Type
  newTypeTuple :: a -> Maybe (Vector.Vector Types_Types.Type) -> IO Types_Types.Type
  graph :: a -> Maybe Defs_Types.NodeDefinition -> IO Graph_Types.Graph
  addNode :: a -> Maybe Graph_Types.Node -> Maybe Defs_Types.NodeDefinition -> IO Graph_Types.Node
  updateNode :: a -> Maybe Graph_Types.Node -> Maybe Defs_Types.NodeDefinition -> IO ()
  removeNode :: a -> Maybe Graph_Types.Node -> Maybe Defs_Types.NodeDefinition -> IO ()
  connect :: a -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Defs_Types.NodeDefinition -> IO ()
  disconnect :: a -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Graph_Types.Node -> Maybe (Vector.Vector Int32) -> Maybe Defs_Types.NodeDefinition -> IO ()
  ping :: a -> IO ()
