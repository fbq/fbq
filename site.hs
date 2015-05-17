--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll

--------------------------------------------------------------------------------
-- Site Configuration

title :: String
title = "朝闻道"

description :: String
description = "For the Eureka!"

host :: String
host = "fbq.github.io"

authorName :: String
authorName = "Boqun Feng"

authorEmail :: String
authorEmail = "boqun.feng@gmail.com"

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = title
    , feedDescription = description
    , feedAuthorName  = authorName
    , feedAuthorEmail = authorEmail
    , feedRoot        = "https://" ++ host
    }

-- hakyll's configuration
config :: Configuration
config = defaultConfiguration

-- add "date" to post context
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    -- basic static files for blog
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- about page
    match "about.markdown" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    -- all posts
    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            -- save a snaphot for feed
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/comment.html" postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    -- archive of all posts
    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            makeListItem posts postCtx "Archive" "templates/archive.html"

    -- all notes
    match "notes/**" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/note.html"    postCtx
            >>= loadAndApplyTemplate "templates/comment.html" postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    -- index of all notes
    create ["notes.html"] $ do
        route idRoute
        compile $ do
            notes <- loadAll "notes/**"
            makeListItem notes defaultContext "Notes" "templates/notes.html"

    -- index page
    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "items" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    -- templates
    match "templates/*" $ compile templateCompiler

    -- feed
    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"
            posts <- recentFirst =<<
                loadAllSnapshots "posts/*" "content"
            renderAtom myFeedConfiguration feedCtx posts

--------------------------------------------------------------------------------
makeListItem :: [Item a]-> Context a -> String -> Identifier -> Compiler (Item String)
makeListItem items itemCtx title template = do
    let archiveCtx =
            listField "items" itemCtx (return items) `mappend`
            constField "title" title                 `mappend`
            defaultContext

    makeItem ""
        >>= loadAndApplyTemplate template archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls
