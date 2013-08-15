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

module Defs_Types where
import Prelude ( Bool(..), Enum, Double, String, Maybe(..),
                 Eq, Show, Ord,
                 return, length, IO, fromIntegral, fromEnum, toEnum,
                 (.), (&&), (||), (==), (++), ($), (-) )

import           Control.Exception      
import           Data.ByteString.Lazy   
import           Data.Hashable          
import           Data.Int               
import           Data.Text.Lazy         ( Text )
import qualified Data.Text.Lazy       as TL
import           Data.Typeable          ( Typeable )
import qualified Data.HashMap.Strict  as Map
import qualified Data.HashSet         as Set
import qualified Data.Vector          as Vector

import           Thrift                 
import           Thrift.Types           ()

import           Attrs_Types            
import           Graph_Types            
import           Libs_Types             
import           Types_Types            


type DefID = Int32

type Imports = Vector.Vector Import

data Import = Import{f_Import_path :: Maybe (Vector.Vector Text),f_Import_items :: Maybe (Vector.Vector Text)} deriving (Show,Eq,Typeable)
instance Hashable Import where
  hashWithSalt salt record = salt   `hashWithSalt` f_Import_path record   `hashWithSalt` f_Import_items record  
write_Import oprot record = do
  writeStructBegin oprot "Import"
  case f_Import_path record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("path",T_LIST,1)
    (let f = Vector.mapM_ (\_viter2 -> writeString oprot _viter2) in do {writeListBegin oprot (T_STRING,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  case f_Import_items record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("items",T_LIST,2)
    (let f = Vector.mapM_ (\_viter3 -> writeString oprot _viter3) in do {writeListBegin oprot (T_STRING,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_Import_fields iprot record = do
  (_,_t5,_id6) <- readFieldBegin iprot
  if _t5 == T_STOP then return record else
    case _id6 of 
      1 -> if _t5 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) (readString iprot) in do {(_etype10,_size7) <- readListBegin iprot; f _size7})
        read_Import_fields iprot record{f_Import_path=Just s}
        else do
          skip iprot _t5
          read_Import_fields iprot record
      2 -> if _t5 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) (readString iprot) in do {(_etype15,_size12) <- readListBegin iprot; f _size12})
        read_Import_fields iprot record{f_Import_items=Just s}
        else do
          skip iprot _t5
          read_Import_fields iprot record
      _ -> do
        skip iprot _t5
        readFieldEnd iprot
        read_Import_fields iprot record
read_Import iprot = do
  _ <- readStructBegin iprot
  record <- read_Import_fields iprot (Import{f_Import_path=Nothing,f_Import_items=Nothing})
  readStructEnd iprot
  return record
data Definition = Definition{f_Definition_cls :: Maybe Types_Types.Type,f_Definition_imports :: Maybe (Vector.Vector Import),f_Definition_flags :: Maybe Attrs_Types.Flags,f_Definition_attribs :: Maybe Attrs_Types.Attributes,f_Definition_defID :: Maybe Int32} deriving (Show,Eq,Typeable)
instance Hashable Definition where
  hashWithSalt salt record = salt   `hashWithSalt` f_Definition_cls record   `hashWithSalt` f_Definition_imports record   `hashWithSalt` f_Definition_flags record   `hashWithSalt` f_Definition_attribs record   `hashWithSalt` f_Definition_defID record  
write_Definition oprot record = do
  writeStructBegin oprot "Definition"
  case f_Definition_cls record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("cls",T_STRUCT,1)
    Types_Types.write_Type oprot _v
    writeFieldEnd oprot}
  case f_Definition_imports record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("imports",T_LIST,2)
    (let f = Vector.mapM_ (\_viter19 -> write_Import oprot _viter19) in do {writeListBegin oprot (T_STRUCT,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  case f_Definition_flags record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("flags",T_STRUCT,3)
    Attrs_Types.write_Flags oprot _v
    writeFieldEnd oprot}
  case f_Definition_attribs record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("attribs",T_STRUCT,4)
    Attrs_Types.write_Attributes oprot _v
    writeFieldEnd oprot}
  case f_Definition_defID record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("defID",T_I32,5)
    writeI32 oprot _v
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_Definition_fields iprot record = do
  (_,_t21,_id22) <- readFieldBegin iprot
  if _t21 == T_STOP then return record else
    case _id22 of 
      1 -> if _t21 == T_STRUCT then do
        s <- (read_Type iprot)
        read_Definition_fields iprot record{f_Definition_cls=Just s}
        else do
          skip iprot _t21
          read_Definition_fields iprot record
      2 -> if _t21 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) ((read_Import iprot)) in do {(_etype26,_size23) <- readListBegin iprot; f _size23})
        read_Definition_fields iprot record{f_Definition_imports=Just s}
        else do
          skip iprot _t21
          read_Definition_fields iprot record
      3 -> if _t21 == T_STRUCT then do
        s <- (read_Flags iprot)
        read_Definition_fields iprot record{f_Definition_flags=Just s}
        else do
          skip iprot _t21
          read_Definition_fields iprot record
      4 -> if _t21 == T_STRUCT then do
        s <- (read_Attributes iprot)
        read_Definition_fields iprot record{f_Definition_attribs=Just s}
        else do
          skip iprot _t21
          read_Definition_fields iprot record
      5 -> if _t21 == T_I32 then do
        s <- readI32 iprot
        read_Definition_fields iprot record{f_Definition_defID=Just s}
        else do
          skip iprot _t21
          read_Definition_fields iprot record
      _ -> do
        skip iprot _t21
        readFieldEnd iprot
        read_Definition_fields iprot record
read_Definition iprot = do
  _ <- readStructBegin iprot
  record <- read_Definition_fields iprot (Definition{f_Definition_cls=Nothing,f_Definition_imports=Nothing,f_Definition_flags=Nothing,f_Definition_attribs=Nothing,f_Definition_defID=Nothing})
  readStructEnd iprot
  return record
data DEdge = DEdge{f_DEdge_src :: Maybe Int32,f_DEdge_dst :: Maybe Int32} deriving (Show,Eq,Typeable)
instance Hashable DEdge where
  hashWithSalt salt record = salt   `hashWithSalt` f_DEdge_src record   `hashWithSalt` f_DEdge_dst record  
write_DEdge oprot record = do
  writeStructBegin oprot "DEdge"
  case f_DEdge_src record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("src",T_I32,1)
    writeI32 oprot _v
    writeFieldEnd oprot}
  case f_DEdge_dst record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("dst",T_I32,2)
    writeI32 oprot _v
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_DEdge_fields iprot record = do
  (_,_t31,_id32) <- readFieldBegin iprot
  if _t31 == T_STOP then return record else
    case _id32 of 
      1 -> if _t31 == T_I32 then do
        s <- readI32 iprot
        read_DEdge_fields iprot record{f_DEdge_src=Just s}
        else do
          skip iprot _t31
          read_DEdge_fields iprot record
      2 -> if _t31 == T_I32 then do
        s <- readI32 iprot
        read_DEdge_fields iprot record{f_DEdge_dst=Just s}
        else do
          skip iprot _t31
          read_DEdge_fields iprot record
      _ -> do
        skip iprot _t31
        readFieldEnd iprot
        read_DEdge_fields iprot record
read_DEdge iprot = do
  _ <- readStructBegin iprot
  record <- read_DEdge_fields iprot (DEdge{f_DEdge_src=Nothing,f_DEdge_dst=Nothing})
  readStructEnd iprot
  return record
data DefsGraph = DefsGraph{f_DefsGraph_defs :: Maybe (Map.HashMap Int32 Definition),f_DefsGraph_edges :: Maybe (Vector.Vector DEdge)} deriving (Show,Eq,Typeable)
instance Hashable DefsGraph where
  hashWithSalt salt record = salt   `hashWithSalt` f_DefsGraph_defs record   `hashWithSalt` f_DefsGraph_edges record  
write_DefsGraph oprot record = do
  writeStructBegin oprot "DefsGraph"
  case f_DefsGraph_defs record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("defs",T_MAP,1)
    (let {f [] = return (); f ((_kiter35,_viter36):t) = do {do {writeI32 oprot _kiter35;write_Definition oprot _viter36};f t}} in do {writeMapBegin oprot (T_I32,T_STRUCT,fromIntegral $ Map.size _v); f (Map.toList _v);writeMapEnd oprot})
    writeFieldEnd oprot}
  case f_DefsGraph_edges record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("edges",T_LIST,2)
    (let f = Vector.mapM_ (\_viter37 -> write_DEdge oprot _viter37) in do {writeListBegin oprot (T_STRUCT,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_DefsGraph_fields iprot record = do
  (_,_t39,_id40) <- readFieldBegin iprot
  if _t39 == T_STOP then return record else
    case _id40 of 
      1 -> if _t39 == T_MAP then do
        s <- (let {f 0 = return []; f n = do {k <- readI32 iprot; v <- (read_Definition iprot);r <- f (n-1); return $ (k,v):r}} in do {(_ktype42,_vtype43,_size41) <- readMapBegin iprot; l <- f _size41; return $ Map.fromList l})
        read_DefsGraph_fields iprot record{f_DefsGraph_defs=Just s}
        else do
          skip iprot _t39
          read_DefsGraph_fields iprot record
      2 -> if _t39 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) ((read_DEdge iprot)) in do {(_etype49,_size46) <- readListBegin iprot; f _size46})
        read_DefsGraph_fields iprot record{f_DefsGraph_edges=Just s}
        else do
          skip iprot _t39
          read_DefsGraph_fields iprot record
      _ -> do
        skip iprot _t39
        readFieldEnd iprot
        read_DefsGraph_fields iprot record
read_DefsGraph iprot = do
  _ <- readStructBegin iprot
  record <- read_DefsGraph_fields iprot (DefsGraph{f_DefsGraph_defs=Nothing,f_DefsGraph_edges=Nothing})
  readStructEnd iprot
  return record
data DefManager = DefManager{f_DefManager_defs :: Maybe (Vector.Vector Definition),f_DefManager_graphs :: Maybe (Vector.Vector Graph_Types.Graph),f_DefManager_edges :: Maybe (Vector.Vector DEdge)} deriving (Show,Eq,Typeable)
instance Hashable DefManager where
  hashWithSalt salt record = salt   `hashWithSalt` f_DefManager_defs record   `hashWithSalt` f_DefManager_graphs record   `hashWithSalt` f_DefManager_edges record  
write_DefManager oprot record = do
  writeStructBegin oprot "DefManager"
  case f_DefManager_defs record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("defs",T_LIST,1)
    (let f = Vector.mapM_ (\_viter53 -> write_Definition oprot _viter53) in do {writeListBegin oprot (T_STRUCT,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  case f_DefManager_graphs record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("graphs",T_LIST,2)
    (let f = Vector.mapM_ (\_viter54 -> Graph_Types.write_Graph oprot _viter54) in do {writeListBegin oprot (T_STRUCT,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  case f_DefManager_edges record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("edges",T_LIST,3)
    (let f = Vector.mapM_ (\_viter55 -> write_DEdge oprot _viter55) in do {writeListBegin oprot (T_STRUCT,fromIntegral $ Vector.length _v); f _v;writeListEnd oprot})
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_DefManager_fields iprot record = do
  (_,_t57,_id58) <- readFieldBegin iprot
  if _t57 == T_STOP then return record else
    case _id58 of 
      1 -> if _t57 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) ((read_Definition iprot)) in do {(_etype62,_size59) <- readListBegin iprot; f _size59})
        read_DefManager_fields iprot record{f_DefManager_defs=Just s}
        else do
          skip iprot _t57
          read_DefManager_fields iprot record
      2 -> if _t57 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) ((read_Graph iprot)) in do {(_etype67,_size64) <- readListBegin iprot; f _size64})
        read_DefManager_fields iprot record{f_DefManager_graphs=Just s}
        else do
          skip iprot _t57
          read_DefManager_fields iprot record
      3 -> if _t57 == T_LIST then do
        s <- (let f n = Vector.replicateM (fromIntegral n) ((read_DEdge iprot)) in do {(_etype72,_size69) <- readListBegin iprot; f _size69})
        read_DefManager_fields iprot record{f_DefManager_edges=Just s}
        else do
          skip iprot _t57
          read_DefManager_fields iprot record
      _ -> do
        skip iprot _t57
        readFieldEnd iprot
        read_DefManager_fields iprot record
read_DefManager iprot = do
  _ <- readStructBegin iprot
  record <- read_DefManager_fields iprot (DefManager{f_DefManager_defs=Nothing,f_DefManager_graphs=Nothing,f_DefManager_edges=Nothing})
  readStructEnd iprot
  return record
