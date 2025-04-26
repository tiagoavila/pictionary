export const InitializeCanvas = {
    mounted() {
        let SELF = this;
        const canvas = document.getElementById('drawingCanvas');
        if (!canvas) {
            return;
        }

        const context = canvas.getContext('2d');

        const drawBtn = document.getElementById("drawBtn");
        const fillBtn = document.getElementById("fillBtn");
        const clearBtn = document.getElementById("clearBtn");
        const colorPicker = document.getElementById("colorInput");
        const fillColorInput = document.getElementById("fillColorInput");

        let isDrawing = false;
        let mode = "draw"; // "draw" or "fill"

        let coordinates = [];

        let initialDrawTime = Date.now();
        let finalDrawTime = Date.now();

        // Set up canvas listeners
        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', draw);
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
            context.fillStyle = "white";
            context.fillRect(0, 0, canvas.width, canvas.height);
            context.fillStyle = colorInput.value;
        }

        function changeColor() {
            context.strokeStyle = colorPicker.value;
        }

        function startDrawing(event) {
            if (mode === "draw") {
                initialDrawTime = Date.now();
                coordinates = [];
                isDrawing = true;
                context.beginPath();
                context.moveTo(event.offsetX, event.offsetY);
            }  else if (mode === "fill") {
                const rect = canvas.getBoundingClientRect();
                const x = Math.floor(event.clientX - rect.left);
                const y = Math.floor(event.clientY - rect.top);
                floodFill(x, y, fillColorInput.value);
            }
        }

        function draw(event) {
            if (!isDrawing) return;
            if (mode === "fill") return; // Prevent drawing while in fill mode

            context.lineTo(event.offsetX, event.offsetY);
            context.stroke();

            coordinates.push([event.offsetX, event.offsetY]);
        }

        function stopDrawing() {
            if (!isDrawing) return;
            if (mode === "fill") return; // Prevent drawing while in fill mode

            isDrawing = false;
            context.closePath();

            finalDrawTime = Date.now();
            let timeDiff = finalDrawTime - initialDrawTime;

            const gameCode = document.getElementById('game_code').value;
            const playerId = document.getElementById('player_id').value;

            SELF.pushEvent('drawClientToServer', { 
                coordinates: coordinates, 
                color: context.strokeStyle,
                time_diff: timeDiff,
                game_code: gameCode,
                player_id: playerId
            });
        }

        // Flood fill algorithm (4-way fill)
        function floodFill(x, y, fillColor) {
            // Get canvas image data
            const imageData = context.getImageData(0, 0, canvas.width, canvas.height);

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
            context.putImageData(imageData, 0, 0);
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
    },
    updated() {
    }
}

export function addEventListenerForDrawUpdates() {
    window.addEventListener("phx:draw-updated", (e) => {
        const canvas = document.getElementById('drawingCanvas');
        if (!canvas) {
            return;
        }

        const playerId = document.getElementById('player_id').value;
        const parsedObject = JSON.parse(e.detail.data);
        if (parsedObject.player_id === playerId) {
            console.log("same player");
            return; // Ignore updates from the same player
        }

        const context = canvas.getContext('2d');
        context.strokeStyle = parsedObject.color;

        if (parsedObject.coordinates.length > 0) {
            let timeBetweenCoordinatesDrawn = parsedObject.time_diff / parsedObject.coordinates.length;
            // Start a new path
            context.beginPath();

            let first_coordinate = parsedObject.coordinates[0];
            // Move to the first point
            context.moveTo(first_coordinate[0], first_coordinate[1]);

            // Function to draw each coordinate with a delay
            function drawWithDelay(index) {
                if (index >= parsedObject.coordinates.length) {
                    return; // Stop when all coordinates are drawn
                }

                let coordinate = parsedObject.coordinates[index];
                context.lineTo(coordinate[0], coordinate[1]);
                context.stroke();

                // Call the function again after the delay
                setTimeout(() => drawWithDelay(index + 1), timeBetweenCoordinatesDrawn);
            }

            // Start drawing from the first coordinate
            drawWithDelay(1);
        }
});
}

function setButtonToInactive(button) {
    button.classList.remove("bg-blue-500", "text-white");
    button.classList.add("bg-gray-200", "text-gray-800");
}

function setButtonAsActive(button) {
    button.classList.remove("bg-gray-200", "text-gray-800");
    button.classList.add("bg-blue-500", "text-white");
}