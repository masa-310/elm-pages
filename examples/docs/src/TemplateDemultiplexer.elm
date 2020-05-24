module TemplateDemultiplexer exposing (..)

import Element exposing (Element)
import Global
import Head
import Html exposing (Html)
import MarkdownRenderer
import Metadata
import Pages
import Pages.PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import SiteConfig
import Template.BlogPost
import Template.Page
import Template.Showcase


type Metadata
    = MetadataBlogPost Template.BlogPost.Metadata
    | MetadataShowcase Template.Showcase.Metadata
    | MetadataPage Template.Page.Metadata


type alias Model =
    { global : Global.Model
    , page : TemplateModel
    }


type TemplateModel
    = ModelBlogPost Template.BlogPost.Model
    | ModelShowcase Template.Showcase.Model
    | ModelPage Template.Page.Model


type Msg
    = MsgBlogPost Template.BlogPost.Msg
    | MsgGlobal Global.Msg
    | OnPageChange
        { path : PagePath Pages.PathKey
        , query : Maybe String
        , fragment : Maybe String
        , metadata : Metadata
        }


type alias View =
    ( MarkdownRenderer.TableOfContents, List (Element Msg) )


view :
    List ( PagePath Pages.PathKey, Metadata )
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    ->
        StaticHttp.Request
            { view : Model -> View -> { title : String, body : Html Msg }
            , head : List (Head.Tag Pages.PathKey)
            }
view siteMetadata page =
    case page.frontmatter of
        MetadataBlogPost metadata ->
            StaticHttp.map2
                (\data globalData ->
                    { view =
                        \model rendered ->
                            case model.page of
                                ModelBlogPost subModel ->
                                    Template.BlogPost.view data subModel metadata rendered
                                        |> (\{ title, body } ->
                                                Global.wrapBody
                                                    globalData
                                                    page
                                                    model.global
                                                    MsgGlobal
                                                    { title = title
                                                    , body =
                                                        -- Template.BlogPost.liftViewMsg
                                                        body
                                                    }
                                           )

                                _ ->
                                    { title = "", body = Html.text "" }
                    , head = Template.BlogPost.head data page.path metadata
                    }
                )
                (Template.BlogPost.staticData siteMetadata)
                (Global.staticData siteMetadata)

        MetadataShowcase metadata ->
            StaticHttp.map2
                (\data globalData ->
                    { view =
                        \model rendered ->
                            case model.page of
                                ModelShowcase subModel ->
                                    Template.Showcase.view data subModel metadata rendered
                                        |> (\{ title, body } ->
                                                Global.wrapBody
                                                    globalData
                                                    page
                                                    model.global
                                                    MsgGlobal
                                                    { title = title
                                                    , body =
                                                        -- Template.BlogPost.liftViewMsg
                                                        body
                                                    }
                                           )

                                _ ->
                                    { title = "", body = Html.text "" }
                    , head = Template.Showcase.head data page.path metadata
                    }
                )
                (Template.Showcase.staticData siteMetadata)
                (Global.staticData siteMetadata)

        MetadataPage metadata ->
            StaticHttp.map2
                (\data globalData ->
                    { view =
                        \model rendered ->
                            case model.page of
                                ModelPage subModel ->
                                    Template.Page.view data subModel metadata rendered
                                        |> (\{ title, body } ->
                                                Global.wrapBody
                                                    globalData
                                                    page
                                                    model.global
                                                    MsgGlobal
                                                    { title = title
                                                    , body =
                                                        -- Template.BlogPost.liftViewMsg
                                                        body
                                                    }
                                           )

                                _ ->
                                    { title = "", body = Html.text "" }
                    , head = Template.Page.head data page.path metadata
                    }
                )
                (Template.Page.staticData siteMetadata)
                (Global.staticData siteMetadata)


init :
    Maybe
        { path :
            { path : PagePath Pages.PathKey
            , query : Maybe String
            , fragment : Maybe String
            }
        , metadata : Metadata
        }
    -> ( Model, Cmd Msg )
init maybePagePath =
    ( { global = Global.init maybePagePath
      , page =
            case maybePagePath |> Maybe.map .metadata of
                Nothing ->
                    Debug.todo ""

                Just meta ->
                    case meta of
                        MetadataBlogPost metadata ->
                            Template.BlogPost.init metadata
                                |> ModelBlogPost

                        MetadataShowcase metadata ->
                            Template.Showcase.init metadata
                                |> ModelShowcase

                        MetadataPage metadata ->
                            Template.Page.init metadata
                                |> ModelPage
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgBlogPost msg_ ->
            ( model, Cmd.none )

        MsgGlobal msg_ ->
            let
                ( globalModel, globalCmd ) =
                    Global.update msg_ model.global
            in
            ( { model | global = globalModel }, globalCmd |> Cmd.map MsgGlobal )

        OnPageChange record ->
            init <|
                Just
                    { path =
                        { path = record.path
                        , query = record.query
                        , fragment = record.fragment
                        }
                    , metadata = record.metadata
                    }


mainTemplate { documents, manifest, canonicalSiteUrl } =
    Pages.Platform.init
        { init = init
        , view = view
        , update = update

        --, subscriptions = subscriptions
        , subscriptions = \_ -> Sub.none
        , documents = documents

        --[ { extension = "md"
        --  , metadata = Metadata.decoder
        --  , body = MarkdownRenderer.view
        --  }
        --]
        --, onPageChange = Just OnPageChange
        , onPageChange = Just OnPageChange
        , manifest = manifest -- SiteConfig.manifest
        , canonicalSiteUrl = canonicalSiteUrl -- SiteConfig.canonicalUrl
        , internals = Pages.internals
        }
        |> Pages.Platform.toProgram