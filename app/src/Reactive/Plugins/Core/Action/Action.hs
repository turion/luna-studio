module Reactive.Plugins.Core.Action.Action where

import           Data.Monoid          ( (<>) )
import           Data.Default
import           Control.Lens

import           Utils.PrettyPrinter

data WithState act st = WithState { _action :: act
                                  , _state  :: st
                                  } deriving (Eq, Show)


makeLenses ''WithState

instance (Default act, Default st) => Default (WithState act st) where
    def = WithState def def

instance (PrettyPrinter act, PrettyPrinter st) => PrettyPrinter (WithState act st) where
    display (WithState action state) = "na( " <> display action <> " " <> display state <> " )"
