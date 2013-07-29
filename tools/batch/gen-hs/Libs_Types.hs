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

module Libs_Types where
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


type LibID = Int32

data Library = Library{f_Library_libID :: Maybe Int32,f_Library_name :: Maybe Text,f_Library_path :: Maybe Text} deriving (Show,Eq,Typeable)
instance Hashable Library where
  hashWithSalt salt record = salt   `hashWithSalt` f_Library_libID record   `hashWithSalt` f_Library_name record   `hashWithSalt` f_Library_path record  
write_Library oprot record = do
  writeStructBegin oprot "Library"
  case f_Library_libID record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("libID",T_I32,1)
    writeI32 oprot _v
    writeFieldEnd oprot}
  case f_Library_name record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("name",T_STRING,2)
    writeString oprot _v
    writeFieldEnd oprot}
  case f_Library_path record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("path",T_STRING,3)
    writeString oprot _v
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_Library_fields iprot record = do
  (_,_t3,_id4) <- readFieldBegin iprot
  if _t3 == T_STOP then return record else
    case _id4 of 
      1 -> if _t3 == T_I32 then do
        s <- readI32 iprot
        read_Library_fields iprot record{f_Library_libID=Just s}
        else do
          skip iprot _t3
          read_Library_fields iprot record
      2 -> if _t3 == T_STRING then do
        s <- readString iprot
        read_Library_fields iprot record{f_Library_name=Just s}
        else do
          skip iprot _t3
          read_Library_fields iprot record
      3 -> if _t3 == T_STRING then do
        s <- readString iprot
        read_Library_fields iprot record{f_Library_path=Just s}
        else do
          skip iprot _t3
          read_Library_fields iprot record
      _ -> do
        skip iprot _t3
        readFieldEnd iprot
        read_Library_fields iprot record
read_Library iprot = do
  _ <- readStructBegin iprot
  record <- read_Library_fields iprot (Library{f_Library_libID=Nothing,f_Library_name=Nothing,f_Library_path=Nothing})
  readStructEnd iprot
  return record
