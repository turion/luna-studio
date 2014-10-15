module Test.Luna.TypecheckerSpec (spec) where

import Luna.Typechecker.AST
import Luna.Typechecker.Substitution
import Luna.Typechecker.Type
import Luna.Typechecker.TypeEnv
import Luna.Typechecker.TypecheckClass
import Logger

import Test.Hspec

import Control.Monad
import Data.Functor.Identity



shouldInferenceSatisfy :: (Inference a) => a -> [(Subst, Type) -> Expectation] -> Expectation
t `shouldInferenceSatisfy` expectations = do
  let (res, stack) = runIdentity . runLoggerT . infer mkTypeEnv $ t
  case res of
    Left err -> expectationFailure $ "typechecking error:\n" ++ formatStack True stack
    Right res -> mapM_ ($res) expectations

shouldBeInferredTo :: (Inference a) => a -> Type -> Expectation
t `shouldBeInferredTo` val = t `shouldInferenceSatisfy` [(\(_,t) -> t `shouldBe` val)]

shouldNotInfer :: (Inference a) => a -> Expectation
shouldNotInfer t = do
  let (res, stack) = runIdentity . runLoggerT . infer mkTypeEnv $ t
  case res of
    Right _ -> expectationFailure $ "typechecking succeeded but it shouldn't have!\n" ++ formatStack True stack
    Left _ -> True `shouldBe` True

spec :: Spec
spec =
  describe "basic typechecking" $ do
    it "typechecks literals" $ do
      LitInt 10      `shouldBeInferredTo` tInt
      LitDouble 10.5 `shouldBeInferredTo` tDouble
      LitStr "ten"   `shouldBeInferredTo` tString
      LitChar 't'    `shouldBeInferredTo` tChar
    -- it "typechecks literals"
    describe "typechecks expressions" $ do
      it "typechecks ELit" $ do
        ELit (LitInt 10     ) `shouldBeInferredTo` tInt
        ELit (LitDouble 10.5) `shouldBeInferredTo` tDouble
        ELit (LitStr "ten"  ) `shouldBeInferredTo` tString
        ELit (LitChar 't'   ) `shouldBeInferredTo` tChar
      -- it "typechecks ELit"

      it "typechecks EVar (alone)" $
        shouldNotInfer $ EVar (VarID "v1")

      it "typechecks EApp" $ pending

      it "typechecks EAbs" $ pending

      it "typechecks ELet" $ do
        ELet (VarID "const_char")
             (ELit (LitChar 'c'))
             (EVar (VarID "const_char")) `shouldBeInferredTo` tChar

  -- describe "basic typechecking"


      --typechecker "Main.luna" (LitInt 10)        `shouldBe` Tycon (TyID "Int")
      --typechecker "Main.luna" (ELit (LitInt 10)) `shouldBe` Tycon (TyID "Int")