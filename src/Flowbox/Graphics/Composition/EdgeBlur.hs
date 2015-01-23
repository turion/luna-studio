
module Flowbox.Graphics.Composition.EdgeBlur (
    BlurType(..) , edges, maskBlur
) where


import           Flowbox.Graphics.Composition.Filter as F

import Flowbox.Graphics.Utils.Utils
import Flowbox.Graphics.Shader.Pipe
import Flowbox.Graphics.Shader.Shader
import Flowbox.Math.Matrix as M

import           Flowbox.Graphics.Prelude            as P hiding (filter)
import           Data.Array.Accelerate               as A hiding (constant, filter, scatter, size, stencil)

import Math.Space.Space



applyKernel :: (IsNum a, Elt a) => Matrix2 a -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
applyKernel kernel img = process img where
    kernelN = id M.>-> id $ kernel
    p = pipe A.Clamp
    process x = id `p` F.filter 1 kernelN `p` id $ x

  --convolve mode kernel
  --  where fi = fmap A.fromIntegral
  --        mode point offset = fi point + fi offset

-- bluredImg = blur n sigma testShader

mixImages :: (Applicative f, Num a) => f a -> f a -> f a -> f a
mixImages edgesMask first second = (+) <$> 
                               ( (*) <$> first <*> edgesMask ) 
                               <*> 
                               ( (*) <$> second <*> (fmap ((-) 1) edgesMask) )

detectEdges :: (Elt a, IsFloating a) => Exp a -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
detectEdges sens img = (\x y -> P.min 1.0 $ sens*x+sens*y) <$>
                       (fmap abs $ applyKernel (M.transpose (sobel {-- :: Matrix2 Double --} )) img) 
                       <*> 
                       (fmap abs $ applyKernel (sobel {-- :: Matrix2 Double --} ) img)

--processImage img = (blur n sigma) (detectEdges img)

--edgeBlur img = mixImages (processImage img) img (blur n sigma img)

--matEdgeBlur matImg mask = rasterizer $ monosampler $ edgeBlur (nearest $ fromMatrix Clamp matImg)

-- edges mat = rasterizer $ monosampler $ blur 25 $ nearest $ dilate (Grid 10 10)  $ erode (Grid 3 3) $ monosampler  $ detectEdges 2 (blur 10 $ nearest $ fromMatrix Clamp mat)

--matBlur size sigma mat = rasterizer $ monosampler $ blur size (nearest $ fromMatrix Clamp mat)

-- eedgeBBlur matteChannel img = forAllChannel img (matEdgeBlur mask)
--                               where mask = edges matteChannel



--edgeBlur :: BlurType -> Exp Int -> Exp Double -> Matrix2 Double -> [Matrix2 Double] -> [Matrix2 Double]
--edgeBlur blurType kernelSize edgeMult matteCh chs = fmap ( rasterizer . blurFunc . (fromMatrix Clamp) ) chs where
--    maskEdges =  edges edgeMult  (fromMatrix Clamp matteCh)
--    blurFunc  = maskBlur blurType kernelSize maskEdges --matteCh 


--edges :: Exp Double -> Matrix2 Double -> CartesianShader (Exp Double) (Exp Double)

edges :: (Elt a, IsFloating a) => Exp a -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
edges edgeMult channel = blurFunc bigEdges where
    blurFunc  = blurChoice GaussBlur 15
    bigEdges  = dilate (Grid 5 5) $ erode (Grid 3 3) thinEdges   
    thinEdges = detectEdges edgeMult imgShader
    imgShader = channel
    


    --blurChoice Gauss 15 $ nearest $ dilate (Grid 5 5) $ erode (Grid 3 3) $ monosampler $ detectEdges edgeMult $ nearest $ fromMatrix Clamp channel

--ebTop' :: String -> Exp Int -> Exp Double -> Matrix2 Double -> [Matrix2 Double] -> [Matrix2 Double]
--ebTop' blurType size sigma matteCh chs =
--  let maskEdges = blur 15 1.0 $ nearest $ {-- dilate (Grid 10 10) $ --} erode (Grid 3 3) $ monosampler $  detectEdges $  nearest $ fromMatrix Clamp matteCh
--      blurF     = maskBlur sigma size maskEdges
--    in fmap blurF chs

--ebTop'' :: String -> Exp Int -> Exp Double -> Matrix2 Double -> [Matrix2 Double] -> [Matrix2 Double]
--ebTop'' blurType size sigma matteCh chs =
--  let maskEdges = blur 15 1.0 $ nearest $  dilate (Grid 10 10) $ {-- erode (Grid 3 3) $ --} monosampler $  detectEdges $  nearest $ fromMatrix Clamp matteCh
--      blurF     = maskBlur sigma size maskEdges
--    in fmap blurF chs

--ebTop''' :: String -> Exp Int -> Exp Double -> Matrix2 Double -> [Matrix2 Double] -> [Matrix2 Double]
--ebTop''' blurType size sigma matteCh chs =
--  let maskEdges = blur 15 1.0 $ nearest $ {-- dilate (Grid 10 10) $  erode (Grid 3 3) $ --} monosampler $  detectEdges $  nearest $ fromMatrix Clamp matteCh
--      blurF     = maskBlur sigma size maskEdges
--    in fmap blurF chs

maskBlur :: (Elt a, IsFloating a) => BlurType -> Exp Int -> DiscreteShader (Exp a) -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
maskBlur blurType size mask img = mixImages mask blured imgShader where
    imgShader = img
      --maskEdges = mask --blur 15 5.0 $  nearest $  dilate (Grid 10 10) $ {-- erode (Grid 3 3) $ --} monosampler $  detectEdges $  nearest $ fromMatrix Clamp mask
    blurFunc  = blurChoice blurType
    blured    = blurFunc size imgShader
    
blurChoice :: (Elt a, IsFloating a) => BlurType -> Exp Int -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
blurChoice blurType = case blurType of
  GaussBlur     -> blur $ gauss 1
  BoxBlur       -> blur   box
  TriangleBlur  -> blur   triangle
  -- Quadratic -> undefined


data BlurType = GaussBlur | BoxBlur | TriangleBlur -- | Quadratic

--edgeBlur' :: Exp Double -> Exp Int -> CartesianShader (Exp Double) (Exp Double) -> Matrix2 Double -> Matrix2 Double
--edgeBlur' sigma size mask img = 
--  let imgShader = nearest $ fromMatrix Clamp img
--      maskEdges = mask -- blur 15 5.0 $ nearest $ dilate (Grid 10 10) $ erode (Grid 3 3) $ monosampler $ detectEdges $ nearest $ fromMatrix Clamp mask
--      blured = blur size sigma imgShader
--      result = mixImages maskEdges blured imgShader
--    in rasterizer $ monosampler $ result


--blurKernel :: Exp Int -> Exp Double -> Matrix2 Double
--blurKernel size sigma = normalize $ toMatrix (Grid size size) (gauss sigma) 

--blurKernelV :: Exp Int -> Exp Double -> Matrix2 Double
--blurKernelV size sigma = normalize $ toMatrix (Grid size 1) (gauss sigma) 

--blurKernelH :: Exp Int -> Exp Double -> Matrix2 Double
--blurKernelH size sigma = normalize $ toMatrix (Grid 1 size) (gauss sigma) 




--blur size sigma img = applyKernel (blurKernelV size sigma) (applyKernel (blurKernelH size sigma) img) -- $ applyKernel $ blurKernelV size sigma
--blur :: Exp Int -> Exp Double -> CartesianShader (Exp Double) (Exp Double) -> CartesianShader (Exp Double) (Exp Double)
--blur size sigma img = nearest $ F.filter 1 (blurKernelV size sigma) $ F.filter 1 (blurKernelV size sigma) $ monosampler img

blur :: (IsFloating a, Elt a) => Filter (Exp a) -> Exp Int -> DiscreteShader (Exp a) -> DiscreteShader (Exp a)
blur kernel kernSize img = process img where
    hmat = id M.>-> normalize $ toMatrix (Grid 1 (variable kernSize)) $ kernel
    vmat = id M.>-> normalize $ toMatrix (Grid (variable kernSize) 1) $ kernel
    p = pipe A.Clamp
    process x = id `p` F.filter 1 vmat `p` F.filter 1 hmat `p` id $ x

--testMat :: Matrix2 Double
--testMat = M.fromList (Z :. 4 :. 4) [  0, 0, 0, 0
--                                    , 0, 1, 1, 0
--                                    , 0, 1, 1, 0
--                                    , 0, 0, 0, 0
--                                   ]

--testShader :: CartesianShader (Exp Double) (Exp Double)
--testShader = nearest $ fromMatrix Clamp testMat

--n :: Exp Int
--n = 5

--sigma :: Exp Double
--sigma = 1

--test = do
--    Prelude.putStrLn "testShader"
--    Prelude.print $ M.toList A.run $ rasterizer $ monosampler $ testShader
--    Prelude.putStrLn "detectEdges"
--    Prelude.print $ M.toList A.run $ rasterizer $ monosampler $ detectEdges testShader
--    --putStrLn "sobel"
--    --print $ show (sobel :: Matrix2 Double)

--    Prelude.putStrLn "blur"
--    Prelude.print $ M.toList A.run $ rasterizer $ monosampler $ blur n sigma testShader

--    Prelude.putStrLn "edges blured"
--    Prelude.print $ M.toList A.run $ rasterizer $ monosampler $ processImage testShader

--    Prelude.putStrLn "mixing test"
--    Prelude.print $ M.toList A.run $ rasterizer $ monosampler $ mixImages (processImage testShader) testShader bluredImg 
