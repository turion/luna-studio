{-# LANGUAGE ScopedTypeVariables #-}

module Flowbox.GuiMockup.LineFit where
-- (
--	  CubicBezier(..)
--	, fitCurve
--	) where

import           Control.Applicative          ((<$>), (<*>))
import           Control.Error                hiding (err)
import           Control.Lens.Operators
import           Control.Monad                (forM_, when)
import           Control.Monad.ST             (runST)
import           Control.Monad.Trans.Class    (lift)
import           Data.STRef
import qualified Data.Vector.Storable         as V
import qualified Data.Vector.Storable.Mutable as MV
import           Foreign.Ptr
import           Foreign.Storable
import           Foreign.Storable.Tuple       ()
import           Linear                       hiding (point)



data CubicBezier a = CubicBezier { cubicC0 :: V2 a
                                 , cubicC1 :: V2 a
                                 , cubicC2 :: V2 a
                                 , cubicC3 :: V2 a
                                 }
    deriving (Eq, Show)

instance Storable a => Storable (CubicBezier a) where
    sizeOf _ = 4 * sizeOf (undefined :: V2 a)
    alignment _ = alignment (undefined :: V2 a)
    peek ptr = CubicBezier <$> peek ptr'
                           <*> peekElemOff ptr' 1
                           <*> peekElemOff ptr' 2
                           <*> peekElemOff ptr' 3
        where
            ptr' = castPtr ptr
    poke ptr (CubicBezier c0 c1 c2 c3) = do
        let ptr' = castPtr ptr
        poke ptr' c0
        pokeElemOff ptr' 1 c1
        pokeElemOff ptr' 2 c2
        pokeElemOff ptr' 3 c3


toVec :: CubicBezier Float -> V.Vector (V2 Float)
toVec (CubicBezier c0 c1 c2 c3) = V.fromList [c0, c1, c2, c3]

-- main function in this module

fitCurve :: V.Vector (V2 Float) -> Float -> V.Vector (CubicBezier Float)
fitCurve points err = fitCubic points tHat1 tHat2 err
    where
        len = V.length points
        tHat1 = computeLeftTangent points 0
        tHat2 = computeRightTangent points $ len - 1

fitCubic :: V.Vector (V2 Float) -> V2 Float -> V2 Float -> Float -> V.Vector (CubicBezier Float)
fitCubic points tHat1 tHat2 err
    | V.length points == 2 =
        let c0 = points V.! 0
            c3 = points V.! 1

            dist = distance (points V.! 1) (points V.! 0) / 3
            c1 = c0 + tHat1 ^* dist
            c2 = c3 + tHat2 ^* dist
        in V.singleton $ CubicBezier c0 c1 c2 c3
    | otherwise = if maxError < err
                    then V.singleton bezCurve
                    else if maxError < iterationError
                           then case iteration of
                                  Left curve       -> V.singleton curve
                                  Right splitPoint -> split splitPoint
                           else split initialSplitPoint
        where
            u = chordLengthParameterize points
            bezCurve = generateBezier points u tHat1 tHat2
            (maxError, initialSplitPoint) = computeMaxError points bezCurve u
            iterationError = max err $ err ** 2

            iteration = runST $ runEitherT $ do
                u' <- lift $ newSTRef u
                splitPoint' <- lift $ newSTRef initialSplitPoint

                forM_ [1..4] $ \_ -> do
                    uVal <- lift $ readSTRef u'
                    let uPrime = reparameterize points uVal bezCurve
                        bezCurveVal = generateBezier points uPrime tHat1 tHat2
                        (maxErrorVal, splitPointVal) = computeMaxError points bezCurveVal uPrime

                    lift $ writeSTRef splitPoint' splitPointVal
                    when (maxErrorVal < iterationError) $ left bezCurveVal

                    lift $ writeSTRef u' uPrime

                lift (readSTRef splitPoint') >>= right

            split splitPoint = leftCurve V.++ rightCurve
                where
                    tHatCenter = computeCenterTangent points splitPoint
                    (left, right) = splitPoints splitPoint points
                    leftCurve = fitCubic left tHat1 tHatCenter err
                    rightCurve = fitCubic right (negated tHatCenter) tHat2 err

splitPoints :: (Storable a) => Int -> V.Vector a -> (V.Vector a, V.Vector a)
splitPoints ix vec = (V.snoc left $ V.head right, right)
    where
        (left, right) = V.splitAt ix vec

reparameterize :: V.Vector (V2 Float) -> V.Vector Float -> CubicBezier Float -> V.Vector Float
reparameterize points u bezierCurve = V.create $ do
    let len = V.length points
    uPrime <- MV.new len

    forM_ [0 .. len - 1] $ \i -> do
        let point = points V.! i
            ui    = u V.! i
        MV.write uPrime i $ newtonRaphsonRootFind bezierCurve point ui

    return uPrime

newtonRaphsonRootFind :: CubicBezier Float -> V2 Float -> Float -> Float
newtonRaphsonRootFind q p u =
    if denominator == 0 then u else u - numerator / denominator
    where
        qu = evalBezier qVector u
        qVector = toVec q
        q1 = V.create $ do
            q1' <- MV.new 3

            forM_ [0..2] $ \i -> do
                MV.write q1' i $ (qVector V.! (i + 1) - qVector V.! i) * 3

            return q1'

        q2 = V.create $ do
            q2' <- MV.new 2

            forM_ [0..1] $ \i -> do
                MV.write q2' i $ (q1 V.! (i + 1) - q1 V.! i) * 2

            return q2'

        q1u = evalBezier q1 u
        q2u = evalBezier q2 u

        numerator = (qu ^. _x - p ^. _x) * q1u ^. _x + (qu ^. _y - p ^. _y) * q1u ^. _y
        denominator = (q1u ^. _x) ** 2 + (q1u ^. _y) ** 2 +
                      (qu ^. _x - p ^. _x) * q2u ^. _x + (qu ^. _y - p ^. _y) * q2u ^. _y


generateBezier :: V.Vector (V2 Float) -> V.Vector Float -> V2 Float -> V2 Float -> CubicBezier Float
generateBezier points uPrime tHat1 tHat2 =
    if alphaL < eps || alphaR < eps
        then let dist = segLength / 3
                 c1 = c0 + tHat1 ^* dist
                 c2 = c3 + tHat2 ^* dist
             in CubicBezier c0 c1 c2 c3
        else let c1 = c0 + tHat1 ^* alphaL
                 c2 = c3 + tHat2 ^* alphaR
             in CubicBezier c0 c1 c2 c3
    where
        c0 = V.head points
        c3 = V.last points

        a = computeAMatrix (V.length points) uPrime tHat1 tHat2
        c = computeC a
        x = computeX points a uPrime

        detC0C1 = det22 c
        detC0X  = det22 $ c & column _y .~ x
        detXC1  = det22 $ c & column _x .~ x

        alphaL = if detC0C1 == 0 then 0 else detXC1 / detC0C1
        alphaR = if detC0C1 == 0 then 0 else detC0X / detC0C1

        segLength = distance (V.last points) (V.head points)
        eps = 1.0e-6 * segLength

computeMaxError :: V.Vector (V2 Float) -> CubicBezier Float -> V.Vector Float -> (Float, Int)
computeMaxError points bezier u = runST $ do
    maxDist <- newSTRef 0
    let len = V.length points
    splitPoint <- newSTRef $ len `div` 2

    forM_ [1 .. len - 1] $ \i -> do
        let p = evalBezier (toVec bezier) $ u V.! i
            v = p - (points V.! i)
            dist = quadrance v

        maxDist' <- readSTRef maxDist
        when (dist >= maxDist') $ do
            writeSTRef maxDist dist
            writeSTRef splitPoint i

    maxDist' <- readSTRef maxDist
    splitPoint' <- readSTRef splitPoint

    return (maxDist' , splitPoint')

evalBezier :: V.Vector (V2 Float) -> Float -> V2 Float
evalBezier vtemp t = runST $ do
    let degree = V.length vtemp - 1
    v <- V.thaw vtemp

    forM_ [1..degree] $ \i -> do
        forM_ [0..degree-i] $ \j -> do
            vj <- MV.read v j
            vj1 <- MV.read v (j + 1)
            MV.write v j $ vj ^* (1 - t) + vj1 ^* t

    MV.read v 0


computeX :: V.Vector (V2 Float) -> V.Vector (V2 Float, V2 Float) -> V.Vector Float -> V2 Float
computeX points a uPrime = runST $ do
    x0 <- newSTRef 0
    x1 <- newSTRef 0

    let len = V.length points
    forM_ [0 .. len - 1] $ \i -> do
        let iPoint = points V.! i
            firstPoint = V.head points
            lastPoint = V.last points
            iUPrime = uPrime V.! i
            -- tmp = iPoint -
            --         firstPoint ^* b0 iUPrime +
            --           firstPoint ^* b1 iUPrime +
            --             lastPoint ^* b2 iUPrime + lastPoint ^* b3 iUPrime
            tmp = iPoint - firstPoint ^* (b0 iUPrime + b1 iUPrime)
                         - lastPoint ^* (b2 iUPrime + b3 iUPrime)
            ai0 = fst $ a V.! i
            ai1 = snd $ a V.! i

        modifySTRef' x0 (+ (ai0 `dot` tmp))
        modifySTRef' x1 (+ (ai1 `dot` tmp))

    x0' <- readSTRef x0
    x1' <- readSTRef x1

    return $ V2 x0' x1'

computeC :: V.Vector (V2 Float, V2 Float) -> M22 Float
computeC a = runST $ do
    c00 <- newSTRef 0
    c01 <- newSTRef 0
    c10 <- newSTRef 0
    c11 <- newSTRef 0

    let len = V.length a
    forM_ [0 .. len - 1] $ \i -> do
        let ai0 = fst $ a V.! i
            ai1 = snd $ a V.! i
        modifySTRef' c00 (+ (ai0 `dot` ai0))
        modifySTRef' c01 (+ (ai0 `dot` ai1))
        readSTRef c01 >>= writeSTRef c10
        modifySTRef' c11 (+ (ai1 `dot` ai1))

    c00' <- readSTRef c00
    c01' <- readSTRef c01
    c10' <- readSTRef c10
    c11' <- readSTRef c11

    return $ V2 (V2 c00' c01') (V2 c10' c11')

computeAMatrix :: Int -> V.Vector Float -> V2 Float -> V2 Float -> V.Vector (V2 Float, V2 Float)
computeAMatrix len uPrime tHat1 tHat2 = V.create $ do
    t <- MV.new len

    forM_ [0 .. len - 1] $ \i -> do
        let currentUPrime = uPrime V.! i
            x = tHat1 ^* b1 currentUPrime
            y = tHat2 ^* b2 currentUPrime
        MV.write t i (x, y)

    return t

b0, b1, b2, b3 :: Float -> Float
b0 u = tmp * tmp * tmp
    where
        tmp = 1 - u

b1 u = 3 * u * (tmp * tmp)
    where
        tmp = 1 - u

b2 u = 3 * u * u * tmp
    where
        tmp = 1 - u

b3 u = u * u * u

chordLengthParameterize :: V.Vector (V2 Float) -> V.Vector Float
chordLengthParameterize points = V.create $ do
    u <- MV.new $ V.length points
    MV.write u 0 0

    forM_ [1 .. V.length points - 1] $ \i -> do
        t <- MV.read u (i - 1)
        let dist = distance (points V.! i) (points V.! (i - 1))
        MV.write u i $ t + dist

    last' <- MV.read u (V.length points - 1)

    forM_ [1 .. V.length points - 1] $ \i -> do
        current <- MV.read u i
        MV.write u i $ current / last'

    return u

computeRightTangent :: V.Vector (V2 Float) -> Int -> V2 Float
computeRightTangent points end = tHat2
    where
        tHat2 = normalize tHat2'
        tHat2' = (points V.! (end - 1)) - (points V.! end)

computeLeftTangent :: V.Vector (V2 Float) -> Int -> V2 Float
computeLeftTangent points end = tHat1
    where
        tHat1 = normalize tHat1'
        tHat1' = (points V.! (end + 1)) - (points V.! end)

computeCenterTangent :: V.Vector (V2 Float) -> Int -> V2 Float
computeCenterTangent points center = normalize tHatCenter
    where
        v1 = (points V.! (center - 1)) - (points V.! center)
        v2 = (points V.! center) - (points V.! (center + 1))
        tHatCenter = (v1 + v2) ^/ 2
