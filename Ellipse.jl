using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2

@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"

win = SDL_CreateWindow("Ellipse", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 800, SDL_WINDOW_SHOWN)
SDL_SetWindowResizable(win, SDL_TRUE)

renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

function drawPixel(renderer, x, y)
    LibSDL2.boxRGBA(renderer, 4*x, 4*y, 4*x+4, 4*y+4, 255, 255, 255, 255)
end

try
    x = 160
    y = 100
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
                if scan_code == SDL_SCANCODE_W || scan_code == SDL_SCANCODE_UP
                    y -= 1
                    break
                elseif scan_code == SDL_SCANCODE_A || scan_code == SDL_SCANCODE_LEFT
                    x -= 1
                    break
                elseif scan_code == SDL_SCANCODE_S || scan_code == SDL_SCANCODE_DOWN
                    y += 1
                    break
                elseif scan_code == SDL_SCANCODE_D || scan_code == SDL_SCANCODE_RIGHT
                    x += 1
                    break
                elseif scan_code == SDL_SCANCODE_ESCAPE
                    close = true
                    break
                else
                    break
                end
            end
        end

        x >= 320 && (x = 319;)
        x < 0 && (x = 0;)
        y >= 200 && (y = 199;)
        y < 0 && (y = 0;)

        drawPixel(renderer, x, y)

        SDL_RenderPresent(renderer)

        SDL_Delay(1000 ÷ 60)
    end
finally
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()
end