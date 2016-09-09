{-# LANGUAGE ScopedTypeVariables #-}
module Program.Properties.InvalidProperties where

import Prelude hiding (all)

import System.IO.Unsafe(unsafePerformIO)
import Control.Monad.Random(evalRandIO)

import Algebra.Lattice
import Unicode

import Test.Tasty
import Test.Tasty.Providers (singleTest)
import Test.Tasty.QuickCheck
import Test.Tasty.HUnit

import Test.Tasty.Runners.AntXML
import Test.Tasty.Ingredients.Basic

import Test.Tasty.ExpectedFailure

import Test.QuickCheck (Testable, property)
import Test.QuickCheck.Property (Property(..))

import Data.Ord

import qualified Data.Set as Set
import qualified Data.Map as Map

import Data.Graph.Inductive.Util (trcOfTrrIsTrc)
import Data.Graph.Inductive (mkGraph)
import Data.Graph.Inductive.PatriciaTree (Gr)

import Program (Program)

import Program.Properties.Analysis
import Program.Properties.CDom
import Data.Graph.Inductive.Query.BalancedSCC -- TODO: refactor that module into 2 seperate modules

import Execution (allFinishedExecutionTraces, someFinishedAnnotatedExecutionTraces)
import Program.Examples
import Program.Analysis
import Program.CDom
import Program.Generator (toProgram, GeneratedProgram)

main      = all

all        = defaultMain                               $ expectFail $ tests
allX       = defaultMainWithIngredients [antXMLRunner] $ expectFail $ tests
cdom       = defaultMain                               $ expectFail $ testGroup "cdom"      [ mkTest [cdomTests, cdomCdomTests], mkProp [cdomProps, cdomCdomProps]]
cdomX      = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "cdom"      [ mkTest [cdomTests, cdomCdomTests], mkProp [cdomProps, cdomCdomProps]]
balanced   = defaultMain                               $ expectFail $ testGroup "balanced"  [ mkTest [balancedParanthesesTests], mkProp [balancedParanthesesProps]]
balancedX  = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "balanced"  [ mkTest [balancedParanthesesTests], mkProp [balancedParanthesesProps]]
timing     = defaultMain                               $ expectFail $ testGroup "timing"    [ mkTest [timingClassificationDomPathsTests,precisionCounterExampleTests], mkProp [timingClassificationDomPathsProps] ]
timingX    = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "timing"    [ mkTest [timingClassificationDomPathsTests,precisionCounterExampleTests], mkProp [timingClassificationDomPathsProps] ]
giffhorn   = defaultMain                               $ expectFail $ testGroup "giffhorn"  [ mkTest [giffhornTests], mkProp [giffhornProps] ]
giffhornX  = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "giffhorn"  [ mkTest [giffhornTests], mkProp [giffhornProps] ]
soundness  = defaultMain                               $ expectFail $ testGroup "soundness" [ mkTest [soundnessTests], mkProp [soundnessProps] ]
soundnessX = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "soundness" [ mkTest [soundnessTests], mkProp [soundnessProps] ]
preccex    = defaultMain                               $ expectFail $ testGroup "preccex"   [ mkTest [precisionCounterExampleTests] ]
preccexX   = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "preccex"   [ mkTest [precisionCounterExampleTests] ]

misc       = defaultMain                               $ expectFail $ testGroup "misc"      [ mkProp [miscProps] ]
miscX      = defaultMainWithIngredients [antXMLRunner] $ expectFail $ testGroup "misc"      [ mkProp [miscProps] ]

mkTest = testGroup "Unit tests"
mkProp = testGroup "Properties"


tests :: TestTree
tests = testGroup "Tests" [unitTests, properties]


properties :: TestTree
properties = testGroup "Properties" [ timingClassificationDomPathsProps, giffhornProps, cdomProps, cdomCdomProps, balancedParanthesesProps, soundnessProps ]

unitTests :: TestTree
unitTests  = testGroup "Unit tests" [ timingClassificationDomPathsTests, giffhornTests, cdomTests, cdomCdomTests, balancedParanthesesTests, soundnessTests, precisionCounterExampleTests ]


soundnessProps =  testGroup "(concerning soundness)" [
  ]

soundnessTests =  testGroup "(concerning soundness)" $
  [ testCase      ("allSoundP [ timingClassification using idomChef ] for " ++ exampleName)
                  ( allSoundP [ isSecureTimingClassificationIdomChef ] example @? "")
  | (exampleName, example) <- [ ("cdomIsBroken'", cdomIsBroken') ]
  ] ++
  []


precisionCounterExampleTests = testGroup "(counterxamples to: timingClassification(-DomPaths) is at least as precise as minimalClassification)" $
  []


timingClassificationDomPathsProps = testGroup "(concerning timingClassificationDomPaths)" $ 
  [ testCase ("isSecureTimingCombinedTimingClassification is at least as precise as isSecureTimingClassification for " ++ exampleName)  $   isSecureTimingCombinedTimingClassification p ⊒ isSecureTimingClassification p @? ""
  | (exampleName, p) <- [("timingSecureButNotCombinedTimingSecure", timingSecureButNotCombinedTimingSecure) ]
  ] ++
  []

timingClassificationDomPathsTests = testGroup "(concerning timingClassificationDomPaths)" $
  []



giffhornProps = testGroup "(concerning Giffhorns LSOD)" [
  ]
giffhornTests = testGroup "(concerning Giffhorns LSOD)" $
  []


cdomCdomProps = testGroup "(concerning cdoms)" $
  [ testCase ("cdomIsCdom' idomChef for " ++ exampleName)  $ (cdomIsCdomViolations' p execs idomChef) == [] @? ""
  | (exampleName, p) <- failingCdomIsCdom', let execs = fmap fst $ unsafePerformIO $ evalRandIO $ someFinishedAnnotatedExecutionTraces 100 p defaultInput
  ] ++
  []


cdomCdomTests = testGroup "(concerning cdoms)" $
  []

cdomProps = testGroup "(concerning Chops between cdoms and the nodes involved)" [
  ]

balancedParanthesesProps = testGroup "(concerning sccs, as well as general chops and balanced-parantheses-chops)" [
  ]

balancedParanthesesTests = testGroup "(concerning sccs, as well as general chops and balanced-parantheses-chops)" $
  []

cdomTests = testGroup "(concerning Chops between cdoms and the nodes involved)" $
  []


miscProps = testGroup "(misc)" [
  ]


testPropertySized :: Testable a => Int -> TestName -> a -> TestTree
testPropertySized n name prop = singleTest name $ QC $ (MkProperty $ scale (min n) gen)
   where MkProperty gen = property prop

