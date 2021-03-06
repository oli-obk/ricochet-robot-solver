-- A ricochet robots visualizer and map editor


module Main exposing (..)

import Html exposing (program, div, button)
import Graphics.Render exposing (Point, centered, text, Form, group, solid, circle, ellipse, polygon, filledAndBordered, position, svg, rectangle, filled, angle, fontColor, segment, solidLine, onClick, onMouseDown)
import Color exposing (rgb)
import Mouse exposing (Position)


main : Program Never Model Msg
main =
    program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


fieldSize : Float
fieldSize =
    25


boardSizeInFields : Int
boardSizeInFields =
    16


boardSize : Float
boardSize =
    fieldSize * toFloat boardSizeInFields


viewRow : Int -> List Field -> List (Form Msg)
viewRow y row =
    List.concat (List.indexedMap (viewField y) row)


boardOffset : Float
boardOffset =
    5


indexToPosition : Int -> Float
indexToPosition i =
    (toFloat i) * fieldSize + boardOffset


viewWall : Bool -> Wall -> Int -> Int -> Form Msg
viewWall fill wall x y =
    let
        ( posx, posy ) =
            ( indexToPosition x, indexToPosition y )

        longer =
            if fill then
                -boardOffset / 2
            else
                boardOffset / 2

        ( x1, y1, x2, y2 ) =
            case wall of
                Right ->
                    ( (posx + fieldSize), (posy - longer), (posx + fieldSize), (posy + fieldSize + longer) )

                Bottom ->
                    ( (posx - longer), (posy + fieldSize), (posx + fieldSize + longer), (posy + fieldSize) )
    in
        onClick (ToggleWall x y wall)
            (drawLine ( x1, y1 )
                ( x2, y2 )
                (if fill then
                    Color.black
                 else
                    Color.lightGray
                )
                boardOffset
            )


viewField : Int -> Int -> Field -> List (Form Msg)
viewField y x field =
    List.concat
        [ [ (viewWall field.right
                Right
                x
                y
            )
          , (viewWall field.bottom
                Bottom
                x
                y
            )
          ]
        , (if x == boardSizeInFields - 1 then
            [ (viewWall field.right
                Right
                -1
                y
              )
            ]
           else
            []
          )
        , (if y == boardSizeInFields - 1 then
            [ (viewWall field.bottom
                Bottom
                x
                -1
              )
            ]
           else
            []
          )
        ]


viewRobots : Maybe Drag -> Int -> ( Int, Int ) -> Form Msg
viewRobots drag i ( x, y ) =
    onMouseDown (\( x, y ) -> DragStart { x = round x, y = round y } i)
        (drawCircle
            ( (indexToPosition x)
                + fieldSize
                / 2
                + Maybe.withDefault 0
                    (Maybe.map
                        (\drag ->
                            if drag.object == i then
                                (toFloat (drag.current.x - drag.start.x))
                            else
                                0
                        )
                        drag
                    )
            , (indexToPosition y)
                + fieldSize
                / 2
                + Maybe.withDefault 0
                    (Maybe.map
                        (\drag ->
                            if drag.object == i then
                                (toFloat (drag.current.y - drag.start.y))
                            else
                                0
                        )
                        drag
                    )
            )
            (case i of
                0 ->
                    Color.red

                1 ->
                    Color.green

                2 ->
                    Color.blue

                3 ->
                    Color.yellow

                x ->
                    Color.black
            )
            (fieldSize / 3)
        )


view : Model -> Html.Html Msg
view model =
    svg 0
        0
        (boardSize
            + 10
        )
        (boardSize
            + 10
        )
        (group
            (List.append
                (List.concat
                    (List.indexedMap
                        viewRow
                        model.board
                    )
                )
                (List.indexedMap
                    (viewRobots model.drag)
                    model.positions
                )
            )
         --[
         -- drawRectangle boardSize boardSize ( boardSize / 2, boardSize / 2 ) Color.lightGray
         --, drawEllipse ( 30, 30 )
         --, drawCircle ( boardSize - 30, 30 )
         --, drawEllipse ( boardSize - 30, boardSize - 30 )
         --, drawCircle ( 30, boardSize - 30 )
         --, drawPolygon ( 100, 100 ) (degrees 210) Color.green
         --, drawPolygon ( 150, 100 ) (degrees 160) Color.yellow
         --, drawForm ( 1000, 200 ) (degrees 10)
         --, drawText "Demo text" 60 ( boardSize / 2, boardSize / 2 ) Color.black
         --]
        )


drawPolygon : Point -> Float -> Color.Color -> Form msg
drawPolygon pos rotation color =
    polygon [ ( 0, 0 ), ( 10, -10 ), ( 10, -20 ), ( -10, -20 ), ( -10, -10 ) ]
        |> filled (solid <| color)
        |> angle rotation
        |> position pos


drawRectangle : Float -> Float -> Point -> Color.Color -> Form msg
drawRectangle width height pos color =
    rectangle width height
        |> filled (solid <| color)
        |> position pos


drawLine : Point -> Point -> Color.Color -> Float -> Form msg
drawLine start end color width =
    segment start end
        |> solidLine width (solid color)


drawEllipse : Point -> Form msg
drawEllipse pos =
    ellipse 10 20
        |> filledAndBordered (solid <| rgb 0 0 255)
            5
            (solid <| rgb 0 0 0)
        |> position pos


drawCircle : Point -> Color.Color -> Float -> Form msg
drawCircle pos color size =
    circle size
        |> filled (solid <| color)
        |> position pos


drawText : String -> Int -> Point -> Color.Color -> Form msg
drawText textContent textSize pos color =
    text textSize textContent
        |> fontColor color
        |> centered
        |> position pos



-- MODEL


type alias Model =
    { board : Board
    , positions : RobotPositions
    , drag : Maybe Drag
    }


type alias Drag =
    { -- start is needed to make sure that the robot isn't jumped to the mouse position but instead is smoothly dragged
      start :
        Position
        -- current - start is the offset that needs to be applied to the dragged robot
    , current : Position
    , object : Int
    }


type alias Board =
    List Row


type alias Row =
    List Field


type alias Field =
    { bottom : Bool
    , right : Bool
    }


type alias RobotPositions =
    List ( Int, Int )


field : Field
field =
    { bottom = False, right = False }


model : Model
model =
    let
        most =
            List.repeat 15 (List.append (List.repeat 15 field) [ { field | right = True } ])

        last =
            List.append (List.repeat 15 { field | bottom = True }) [ { field | bottom = True, right = True } ]
    in
        { board = List.append most [ last ]
        , positions = [ ( 1, 1 ), ( 15, 12 ), ( 13, 8 ), ( 6, 6 ) ]
        , drag = Nothing
        }


type Msg
    = ToggleWall Int Int Wall
    | DragStart Position Int
    | DragAt Position
    | DragEnd Position


type Wall
    = Right
    | Bottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleWall x y wall ->
            ( { model | board = toggleBoardWall model.board x y wall }, Cmd.none )

        -- initialize a drag with the current mouse position
        DragStart pos idx ->
            ( { model | drag = Just { start = pos, current = pos, object = idx } }, Cmd.none )

        -- update the visual position of the robot while being dragged
        DragAt pos ->
            ( { model | drag = Maybe.map (\drag -> { drag | current = pos }) model.drag }, Cmd.none )

        -- when the robot is dropped, move it to the target
        DragEnd pos ->
            ( { model | drag = Nothing, positions = Maybe.withDefault model.positions (Maybe.map (updatePosition model.positions) model.drag) }, Cmd.none )


updatePosition : RobotPositions -> Drag -> RobotPositions
updatePosition pos drag =
    List.indexedMap
        (\i val ->
            if i == drag.object then
                -- don't move two robots on the same field
                let
                    newpos =
                        xy2pos drag val
                in
                    if List.any (\pos -> pos == newpos) pos then
                        val
                    else
                        newpos
            else
                val
        )
        pos


{-| Calculate the new grid position from the drag position and the old position.
In case the new grid position is outside the grid, snap back to the old position
-}
xy2pos : Drag -> ( Int, Int ) -> ( Int, Int )
xy2pos drag ( x, y ) =
    let
        newx =
            x + (round (((toFloat drag.current.x - toFloat drag.start.x) / fieldSize)))

        newy =
            y + (round (((toFloat drag.current.y - toFloat drag.start.y) / fieldSize)))
    in
        if newx < 0 || newy < 0 || newx >= boardSizeInFields || newy >= boardSizeInFields then
            ( x, y )
        else
            ( newx, newy )


toggleBoardWall : Board -> Int -> Int -> Wall -> Board
toggleBoardWall board x y wall =
    List.indexedMap
        (\y_i row ->
            (if y_i == y then
                (List.indexedMap
                    (\x_i field ->
                        (if x_i == x then
                            (toggleFieldWall field wall)
                         else
                            field
                        )
                    )
                    row
                )
             else
                row
            )
        )
        board


toggleFieldWall : Field -> Wall -> Field
toggleFieldWall field wall =
    case wall of
        Right ->
            { field | right = not field.right }

        Bottom ->
            { field | bottom = not field.bottom }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.drag of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch [ Mouse.moves DragAt, Mouse.ups DragEnd ]
