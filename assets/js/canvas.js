export const InitializeCanvas = {
    mounted() {
        let SELF = this;
        const canvas = getCanvas();
        if (!canvas) {
            return;
        }

        const context = getCanvasContext(canvas);

        const drawBtn = document.getElementById("drawBtn");
        const fillBtn = document.getElementById("fillBtn");
        const clearBtn = document.getElementById("clearBtn");
        const colorPicker = document.getElementById("colorInput");
        const fillColorInput = document.getElementById("fillColorInput");

        let isDrawing = false;
        let mode = "draw"; // "draw" or "fill"

        // Set up canvas listeners
        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', drawing);
        canvas.addEventListener('mouseup', stopDrawing);
        canvas.addEventListener('mouseout', stopDrawing);

        // Set up color picker listener
        colorPicker.addEventListener('input', changeColor);

        // Set up buttons event listeners
        drawBtn.addEventListener("click", setModeToDraw);
        fillBtn.addEventListener("click", setModeToFill);
        clearBtn.addEventListener("click", clearCanvasDraw);

        function setModeToDraw() {
            mode = "draw";
            setButtonAsActive(drawBtn);
            setButtonToInactive(fillBtn);
        }

        function setModeToFill() {
            mode = "fill";
            setButtonAsActive(fillBtn);
            setButtonToInactive(drawBtn);
        }

        function clearCanvasDraw() {
            let canvas = getCanvas();
            if (!canvas) {
                return;
            }

            let context = getCanvasContext(canvas);
            doClearCanvasDraw(context, canvas);

            pushEventToBackend('clear-draw', {
                game_code: getGameCode(),
                player_id: getPlayerId()
            });
        }

        function changeColor() {
            context.strokeStyle = colorPicker.value;
        }

        function startDrawing(event) {
            if (mode === "draw") {
                isDrawing = true;
                startDraw(context, event.offsetX, event.offsetY);

                let eventData = {
                    click_coordinates: [event.offsetX, event.offsetY],
                    game_code: getGameCode(),
                    player_id: getPlayerId()
                };
                pushEventToBackend('draw-started', eventData); 
            }  else if (mode === "fill") {
                const rect = canvas.getBoundingClientRect();
                const x = Math.floor(event.clientX - rect.left);
                const y = Math.floor(event.clientY - rect.top);
                floodFill(x, y, fillColorInput.value, canvas, context);

                let eventData = {
                    click_coordinates: [x, y],
                    fillColor: fillColorInput.value,
                    game_code: getGameCode(),
                    player_id: getPlayerId() 
                };
                pushEventToBackend('fill-area-updated', eventData); 
            }
        }

        function drawing(event) {
            if (!isDrawing) return;
            if (mode === "fill") return; // Prevent drawing while in fill mode

            draw(context, event.offsetX, event.offsetY);

            let eventData = {
                click_coordinates: [event.offsetX, event.offsetY],
                fillColor: context.strokeStyle,
                game_code: getGameCode(),
                player_id: getPlayerId()
            };
            pushEventToBackend('draw-updated', eventData); 
        }

        function stopDrawing() {
            if (!isDrawing) return;
            if (mode === "fill") return; // Prevent drawing while in fill mode

            isDrawing = false;
        }

        function pushEventToBackend(eventName, eventData) {
            SELF.pushEvent(eventName, eventData);
        }
    },
    updated() {
    }
}

function startDraw(context, x, y) {
    context.beginPath();
    context.moveTo(x, y);
}

export function addEventListenersForDrawUpdates() {
    window.addEventListener("phx:draw-updated", (e) => {
        const canvas = getCanvas();
        if (!canvas) {
            return;
        }

        const playerId = document.getElementById('player_id').value;
        const parsedObject = JSON.parse(e.detail.data);
        if (parsedObject.player_id === playerId) {
            console.log("same player");
            return; // Ignore updates from the same player
        }

        const context = getCanvasContext(canvas);
        context.strokeStyle = parsedObject.color;
        draw(context, parsedObject.click_coordinates[0], parsedObject.click_coordinates[1]);

        console.log("Drawing data received:", parsedObject);
    });

    window.addEventListener("phx:draw-started", (e) => {
        const canvas = getCanvas();
        if (!canvas) {
            return;
        }

        const playerId = document.getElementById('player_id').value;
        const parsedObject = JSON.parse(e.detail.data);
        if (parsedObject.player_id === playerId) {
            console.log("same player");
            return; // Ignore updates from the same player
        }

        const context = getCanvasContext(canvas);

        startDraw(context, parsedObject.click_coordinates[0], parsedObject.click_coordinates[1]);
    });

    window.addEventListener("phx:fill-area-updated", (e) => {
        const canvas = getCanvas();
        if (!canvas) {
            return;
        }

        const playerId = getPlayerId();
        const parsedObject = JSON.parse(e.detail.data);
        if (parsedObject.player_id === playerId) {
            console.log("same player");
            return; // Ignore updates from the same player
        }

        const context = getCanvasContext(canvas);
        context.fillStyle = parsedObject.fillColor;

        // Call the flood fill function with the coordinates
        floodFill(parsedObject.click_coordinates[0], parsedObject.click_coordinates[1], parsedObject.fillColor, canvas, context);
    });

    window.addEventListener("phx:clear-draw", (e) => {
        const canvas = getCanvas();
        if (!canvas) {
            return;
        }

        const playerId = getPlayerId();
        const parsedObject = JSON.parse(e.detail.data);
        if (parsedObject.player_id === playerId) {
            console.log("same player");
            return; // Ignore updates from the same player
        }

        const context = getCanvasContext(canvas);

        doClearCanvasDraw(context, canvas);
    });
}

function draw(context, x, y) {
    context.lineTo(x, y);
    context.stroke();
}

function getCanvas() {
    const canvas = document.getElementById('drawingCanvas');
    if (!canvas) {
        console.error("Canvas not found");
        return null;
    }
    return canvas;
}

function getCanvasContext(canvas) {
    return canvas.getContext('2d');
}

function getPlayerId() {
    return document.getElementById('player_id').value;
}

function getGameCode() {
    return document.getElementById('game_code').value;
}

function setButtonToInactive(button) {
    button.classList.remove("bg-blue-500", "text-white");
    button.classList.add("bg-gray-200", "text-gray-800");
}

function setButtonAsActive(button) {
    button.classList.remove("bg-gray-200", "text-gray-800");
    button.classList.add("bg-blue-500", "text-white");
}

// Flood fill algorithm (4-way fill)
function floodFill(x, y, fillColor, canvas, canvasContext) {
    // Get canvas image data
    const imageData = canvasContext.getImageData(0, 0, canvas.width, canvas.height);

    // Get the color at the clicked position
    const targetColor = getColorAt(imageData, x, y);

    // Convert fill color from hex to RGB
    const fillColorRGB = hexToRgb(fillColor);

    // Don't fill if the target color is the same as the fill color
    if (colorsMatch(targetColor, [fillColorRGB.r, fillColorRGB.g, fillColorRGB.b, 255])) {
        return;
    }

    // Stack for flood fill algorithm (instead of recursion to avoid stack overflow)
    const stack = [{ x, y }];

    while (stack.length > 0) {
        const current = stack.pop();
        const cx = current.x;
        const cy = current.y;

        // Check if the pixel is within bounds and has the target color
        if (cx < 0 || cx >= canvas.width || cy < 0 || cy >= canvas.height) {
            continue;
        }

        const currentColor = getColorAt(imageData, cx, cy);
        if (!colorsMatch(currentColor, targetColor)) {
            continue;
        }

        // Set the pixel color to the fill color
        setColorAt(imageData, cx, cy, [fillColorRGB.r, fillColorRGB.g, fillColorRGB.b, 255]);

        // Add neighboring pixels to the stack
        stack.push({ x: cx + 1, y: cy });  // Right
        stack.push({ x: cx - 1, y: cy });  // Left
        stack.push({ x: cx, y: cy + 1 });  // Down
        stack.push({ x: cx, y: cy - 1 });  // Up
    }

    // Put the modified image data back to the canvas
    canvasContext.putImageData(imageData, 0, 0);
}

/**
 * Helper function to get the color at a specific pixel
 * @param {*} imageData canvas image data 
 * @param {*} x x coordinate of the pixel
 * @param {*} y y coordinate of the pixel
 * @returns 
 */
function getColorAt(imageData, x, y) {
    const index = (y * imageData.width + x) * 4;
    return [
        imageData.data[index],     // R
        imageData.data[index + 1], // G
        imageData.data[index + 2], // B
        imageData.data[index + 3]  // A
    ];
}

/**
 * Helper function to set the color at a specific pixel
 * @param {*} imageData canvas image data 
 * @param {*} x x coordinate of the pixel
 * @param {*} y y coordinate of the pixel
 * @param {*} color color array in RGBA format to set
 */
function setColorAt(imageData, x, y, color) {
    const index = (y * imageData.width + x) * 4;
    imageData.data[index] = color[0];     // R
    imageData.data[index + 1] = color[1]; // G
    imageData.data[index + 2] = color[2]; // B
    imageData.data[index + 3] = color[3]; // A
}

/**
 * Helper function to check if two colors match
 * @param {*} color1 
 * @param {*} color2 
 * @returns 
 */
function colorsMatch(color1, color2) {
    return color1[0] === color2[0] &&
        color1[1] === color2[1] &&
        color1[2] === color2[2] &&
        color1[3] === color2[3];
}

/**
 * Helper function to convert hex color to RGB
 * @param {*} hex 
 * @returns 
 */
function hexToRgb(hex) {
    // Remove the # if present
    hex = hex.replace('#', '');

    // Parse the hex values
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    return { r, g, b };
}

function doClearCanvasDraw(context, canvas) {
    context.fillStyle = "white";
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = colorInput.value;
}