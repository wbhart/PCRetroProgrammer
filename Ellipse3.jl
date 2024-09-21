using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2

# Initialize SDL and SDL_TTF
@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "Error initializing SDL: $(unsafe_string(SDL_GetError()))"
@assert SimpleDirectMediaLayer.TTF_Init() == 0 "Error initializing SDL_TTF: $(unsafe_string(SDL_GetError()))"

# Create a window and renderer
win = SDL_CreateWindow("Ellipse", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 800, SDL_WINDOW_SHOWN)
SDL_SetWindowResizable(win, SDL_TRUE)
renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

# Load a font (ensure you have a valid .ttf font file)
font_path = "times.ttf"
font = SimpleDirectMediaLayer.TTF_OpenFont("times.ttf", 48)
if font == C_NULL
    println(unsafe_string(SimpleDirectMediaLayer.SDL_GetError()))
    exit(1)
end

function render_text(renderer, font, text, x, y)
    color = SDL_Color(255, 255, 255, 255)  # White color
    surface = SimpleDirectMediaLayer.TTF_RenderText_Solid(font, text, color)
    if surface == C_NULL
        println(unsafe_string(SimpleDirectMediaLayer.SDL_GetError()))
        return
    end
    texture = SDL_CreateTextureFromSurface(renderer, surface)
    SDL_FreeSurface(surface)
    
    # Use Ref to pass w and h as mutable references
    w = Ref{Int32}(0)
    h = Ref{Int32}(0)
    
    # Query the texture for its width and height
    SDL_QueryTexture(texture, C_NULL, C_NULL, w, h)
    
    rect = SDL_Rect(x, y, w[], h[])
    SDL_RenderCopy(renderer, texture, C_NULL, Ref(rect))
    SDL_DestroyTexture(texture)
end

# Function to draw a filled rectangle (helper for drawing pixels)
function drawFilledRect(renderer, x, y, w, h, r, g, b, a)
    LibSDL2.filledTrigonRGBA(renderer, x, y, x + w, y, x + w, y + h, r, g, b, a)
    LibSDL2.filledTrigonRGBA(renderer, x, y, x + w, y + h, x, y + h, r, g, b, a)
end

# Function to draw individual pixel
function drawPixel(renderer, x, y)
    drawFilledRect(renderer, 4*x-2, 4*y-2, 4, 4, 255, 255, 255, 255)
end

# Function to clear the screen
function clear(renderer)
    drawFilledRect(renderer, 0, 0, 1279, 799, 0, 0, 0, 255)
end

# Function to create and draw a rotated red ellipse in the offscreen buffer
function draw_rotated_red_ellipse(renderer, w, h, θ)
    # Create an off-screen texture
    offscreen_texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 1280, 800)
    @assert offscreen_texture != C_NULL "Error creating offscreen texture"

    # Set the texture as the render target
    SDL_SetRenderTarget(renderer, offscreen_texture)

    # Clear the off-screen texture
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0)  # Transparent background
    SDL_RenderClear(renderer)

    # Draw a red ellipse centered on the screen
    cx, cy = 640, 400  # Center of the screen
    rw, rh = 4*w, 4*h  # Width and height of the ellipse
    LibSDL2.ellipseRGBA(renderer, cx, cy, rw, rh, 255, 0, 0, 255)  # Draw the red ellipse

    # Reset the render target to the screen
    SDL_SetRenderTarget(renderer, C_NULL)

    # Prepare rotation of the offscreen texture
    center = SDL_Point(640, 400)  # Rotate around the center of the screen
    src_rect = SDL_Rect(0, 0, 1280, 800)
    dest_rect = SDL_Rect(0, 0, 1280, 800)

    # Rotate the offscreen texture by θ
    SDL_RenderCopyEx(renderer, offscreen_texture, Ref(src_rect), Ref(dest_rect), θ * 180 / π, Ref(center), SDL_FLIP_NONE)

    # Clean up the texture
    SDL_DestroyTexture(offscreen_texture)
end

# Function to draw ellipse and display A, B, C, F values
function drawEllipse(renderer, font, r, s, θ::Float64)
    rSq = r*r
    sSq = s*s
    c = sqrt(Float64(rSq - sSq))
    Xf = c*cos(θ)
    Yf = c*sin(θ)
    XfSq = Xf*Xf
    YfSq = Yf*Yf

    A = rSq - XfSq
    B = -2Xf*Yf
    C = rSq - YfSq
    F = rSq*(YfSq - A)

    @assert(A > 0)

    sum = A + abs(B) + C
    sq = (2.0^15 - 4)/sum    # so that rounded sum < 2^23
    fq = -(2.0^31 - 2)/F    # so that rounded F < 2^31
    mq = min(sq, fq)

    A = Int(round(A*mq))
    B = Int(round(B*mq))
    C = Int(round(C*mq))
    F = Int(round(F*mq))

    Δ = B^2 - 4A*C

    k2 = -B/(2A)
    yN = sqrt(Float64(4F)*Float64(A)/Δ)
    xN = k2*yN

    k1 = -B/(2C)
    xE = sqrt(Float64(4F)*Float64(C)/Δ)
    yE = k1*xE

    xNE = sqrt(Float64(F)*Float64(2C-B)^2/(A+C-B)/Δ)
    yNE = (2A-B)*xNE/(2C-B)

    xNW = -sqrt(Float64(F)*Float64(2C+B)^2/(A+B+C)/Δ)
    yNW = -(2A+B)*xNW/(2C+B)

    xH = Int16(round(xN))
    yH = Int16(round(yN))

    xV = Int16(round(xE))
    yV = Int16(round(yE))

    xR = Int16(round(xNE))
    yR = Int16(round(yNE))

    xL = Int16(round(xNW))
    yL = Int16(round(yNW))

    # Draw the points of the ellipse
    drawPixel(renderer, xH + 160, yH + 100)
    drawPixel(renderer, -xH + 160, -yH + 100)

    drawPixel(renderer, xV + 160, yV + 100)
    drawPixel(renderer, -xV + 160, -yV + 100)

    drawPixel(renderer, xL + 160, yL + 100)
    drawPixel(renderer, -xL + 160, -yL + 100)

    drawPixel(renderer, xR + 160, yR + 100)
    drawPixel(renderer, -xR + 160, -yR + 100)

    # Starting Y position for the text (move it upwards a bit)
    start_y = 550

    # Vertical gap between lines
    line_gap = 10
    
    # Render text with a small gap between each line
    render_text(renderer, font, "A: $A", 10, start_y)
    render_text(renderer, font, "B: $B", 10, start_y + 48 + line_gap)  # 48 is the font height, plus a gap
    render_text(renderer, font, "C: $C", 10, start_y + 2*(48 + line_gap))
    render_text(renderer, font, "F: $F", 10, start_y + 3*(48 + line_gap))

    render_text(renderer, font, "r: $r", 300, start_y)
    render_text(renderer, font, "s: $s", 300, start_y + 48 + line_gap)
    render_text(renderer, font, "theta: $θ", 300, start_y + 2*(48 + line_gap))
end

# Main loop
try
    r = 1
    s = 1
    θ = 0.0
    close = false
    while !close
        event_ref = Ref{SDL_Event}()
        while Bool(SDL_PollEvent(event_ref))
            evt = event_ref[]
            evt_ty = evt.type
            if evt_ty == SDL_QUIT
                close = true
                break
            elseif evt_ty == SDL_KEYDOWN
                scan_code = evt.key.keysym.scancode
                if scan_code == SDL_SCANCODE_RIGHT
                    r += 1
                    break
                elseif scan_code == SDL_SCANCODE_LEFT
                    if r > s
                        r -= 1
                    end
                    break
                elseif scan_code == SDL_SCANCODE_UP
                    if s < r
                        s += 1
                    end
                    break
                elseif scan_code == SDL_SCANCODE_DOWN
                    if s > 0
                        s -= 1
                    end
                    break
                elseif scan_code == SDL_SCANCODE_EQUALS
                    θ += 2*π/512
                    break
                elseif scan_code == SDL_SCANCODE_MINUS
                    θ -= 2*π/512
                    break
                elseif scan_code == SDL_SCANCODE_ESCAPE
                    close = true
                    break
                else
                    break
                end
            end
        end
        
        clear(renderer)

        # Draw the rotated red ellipse on the off-screen buffer
        draw_rotated_red_ellipse(renderer, r, s, θ)

        # Draw your custom ellipse
        drawEllipse(renderer, font, r, s, θ)

        SDL_RenderPresent(renderer)

        SDL_Delay(1000 ÷ 60)
    end
finally
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SimpleDirectMediaLayer.TTF_CloseFont(font)
    SimpleDirectMediaLayer.TTF_Quit()
    SDL_Quit()
end
