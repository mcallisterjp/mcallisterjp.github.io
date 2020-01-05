{-# LANGUAGE OverloadedStrings #-}
import           Data.Char (toTitle)
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Options

main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ customPandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    mapM_ specialPage ["archive", "index"]

    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" <> defaultContext

customPandocCompiler :: Compiler (Item String)
customPandocCompiler = pandocCompilerWith customReaderOptions defaultHakyllWriterOptions
    where customReaderOptions = def { readerExtensions = extraReaderExts <> customReaderExts }
          extraReaderExts = extensionsFromList [Ext_auto_identifiers, Ext_ascii_identifiers, Ext_emoji, Ext_backtick_code_blocks]
          customReaderExts = disableExtension Ext_implicit_figures $ pandocExtensions

specialPage :: String -> Rules ()
specialPage p = create [fromFilePath $ p ++ ".html"] $ do
  route idRoute
  compile $ do
    posts <- recentFirst =<< loadAll "posts/*"
    let ctx =
          listField "posts" postCtx (return posts)
          <> constField "title" (toTitle (head p) : tail p)
          <> defaultContext
    makeItem ""
      >>= loadAndApplyTemplate (fromFilePath $ "templates/" ++ p ++ ".html") ctx
      >>= loadAndApplyTemplate "templates/default.html" ctx
      >>= relativizeUrls
