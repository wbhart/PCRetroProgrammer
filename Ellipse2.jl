using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2

@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"

win = SDL_CreateWindow("Ellipse", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 800, SDL_WINDOW_SHOWN)
SDL_SetWindowResizable(win, SDL_TRUE)

renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

function drawFilledRect(renderer, x, y, w, h, r, g, b, a)
    LibSDL2.filledTrigonRGBA(renderer, x, y, x + w, y, x + w, y + h, r, g, b, a)
    LibSDL2.filledTrigonRGBA(renderer, x, y, x + w, y + h, x, y + h, r, g, b, a)
end

function drawPixel(renderer, x, y)
    drawFilledRect(renderer, 4*x, 4*y, 4, 4, 255, 255, 255, 255)
end

function clear(renderer)
    drawFilledRect(renderer, 0, 0, 1279, 799, 0, 0, 0, 255)
end

function drawEllipse(renderer, r, s, θ::Float64)
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
    sq = (2.0^15 - 4)/sum    # so that rounded sum < 2^15

    fq = -(2.0^31 - 2)/F    # so that rounded F < 2^31

    mq = min(sq, fq)

    A = Int32(round(A*mq))
    B = Int32(round(B*mq))
    C = Int32(round(C*mq))
    F = Int32(round(F*mq))

    testA = UInt16(A)
    testB = Int16(B)
    testC = UInt16(C)

    Δ = B^2 - 4A*C

    k2 = -B/(2A)
    yN = sqrt(Float64(4F*A)/Δ)
    xN = k2*yN

    k1 = B/(2C)
    xE = sqrt(Float64(4F*C)/Δ)
    yE = k1*xN

    xNE = sqrt(Float64(F*(2C-B)^2)/((A+C-B)*Δ))
    yNE = (2A-B)*xNE/(2C-B)
    if xNE < yNE*k2
        yNE = -yNE
    end
    
    xNW = -sqrt(Float64(F*(2C+B)^2)/((A+B+C)*Δ))
    yNW = -(2A+B)*xNW/(2C+B)
    if xNW > yNW*k1
        xNW = -xNW
    end
    
    xH = Int16(round(xN))
    yH = Int16(round(yN))

    xV = Int16(round(xE))
    yV = Int16(round(yE))

    xR = Int16(round(xNE))
    yR = Int16(round(yNE))

    xL = Int16(round(xNW))
    yL = Int16(round(yNW))

    drawPixel(renderer, xH + 160, yH + 100)
    drawPixel(renderer, -xH + 160, -yH + 100)

    drawPixel(renderer, xV + 160, yV + 100)
    drawPixel(renderer, -xV + 160, -yV + 100)

    drawPixel(renderer, xL + 160, yL + 100)
    drawPixel(renderer, -xL + 160, -yL + 100)

    drawPixel(renderer, xR + 160, yR + 100)
    drawPixel(renderer, -xR + 160, -yR + 100)
end

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
                if scan_code == scan_code == SDL_SCANCODE_RIGHT
                    r += 1
                    break
                elseif scan_code == scan_code == SDL_SCANCODE_LEFT
                    if r > s
                        r -= 1
                    end
                    break
                elseif scan_code == scan_code == SDL_SCANCODE_UP
                    if s < r
                        s += 1
                    end
                    break
                elseif scan_code == scan_code == SDL_SCANCODE_DOWN
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

        drawEllipse(renderer, r, s, θ)

        SDL_RenderPresent(renderer)

        SDL_Delay(1000 ÷ 60)
    end
finally
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()
end