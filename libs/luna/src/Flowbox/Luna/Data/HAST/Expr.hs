---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Luna.Data.HAST.Expr where

import           Flowbox.Prelude              
import qualified Flowbox.Luna.Data.HAST.Lit as Lit

type Lit = Lit.Lit

data Expr = Assignment { src       :: Expr     , dst       :: Expr                             }
          | Tuple      { items     :: [Expr]                                                   }
          -- | Call       { name      :: String   , args      :: [Expr]   , ctx       :: Context }
          | StringLit  { val       :: String                                                   }
          | NOP        {                                                                       }
          | Var        { name      :: String                                                   }
          | VarE       { name      :: String                                                   }
          | Typed      { cls       :: Expr     , expr      :: Expr                             }
          | TypedP     { cls       :: Expr     , expr      :: Expr                             }
          | Function   { name      :: String   , pats      :: [Expr]   , expr      :: Expr     }
          | LetBlock   { exprs     :: [Expr]   , result    :: Expr                             }
          | DoBlock    { exprs     :: [Expr]                                                   }
          | DataType   { name      :: String   , params    :: [String] , cons      :: [Expr]   }
          | Con        { name      :: String   , fields    :: [Expr]                           }
          | ConE       { qname     :: [String]                                                 }
          | ConT       { name      :: String                                                   }
          | Module     { path      :: [String] , imports   :: [Expr]   , datatypes :: [Expr]  , methods :: [Expr]  }
          | Import     { qualified :: Bool     , segments :: [String]  , rename    :: Maybe String                           }
          | AppE       { src       :: Expr     , dst       :: Expr                             }
          | AppT       { src       :: Expr     , dst       :: Expr                             }
          | Undefined
          -- | VarRef     { vid      :: Int                                                       } 
          -- | NTuple     { items    :: [Expr]                                                    }
          -- | Type       { name     :: String   , params    :: [String]                          }
          -- | Default    { val      :: String                                                    }
          -- | THExprCtx  { name     :: String                                                    }
          -- | THTypeCtx  { name     :: String                                                    }
          -- | At         { name     :: String   , dst       :: Expr                              }
          -- | Any        {                                                                       }
          -- | Block      { body     :: [Expr]   , ctx       :: Context                           }
          -- | BlockRet   { name     :: String   , ctx       :: Context                           }
          -- | FuncType   { items    :: [Expr]                                                    }
           | Infix      { name     :: String   , src       :: Expr     , dst          :: Expr }
           | Lit        { lval     :: Lit                                                     }
          -- | Constant   { cval     :: Constant                                                  }
          deriving (Show)

