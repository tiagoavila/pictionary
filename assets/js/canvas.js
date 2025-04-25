var playerId = document.getElementById('player_id').value;

export const InitializeCanvas = {
    mounted() {
        let SELF = this;
        const canvas = document.getElementById('drawingCanvas');
        if (!canvas) {
            return;
        }

        const context = canvas.getContext('2d');
        let drawing = false;
        const colorPicker = document.getElementById('colorPicker');
        const gameCode = document.getElementById('game_code').value;
        let coordinates = [];
        let initialDrawTime = Date.now();
        let finalDrawTime = Date.now();

        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', draw);
        canvas.addEventListener('mouseup', stopDrawing);
        canvas.addEventListener('mouseout', stopDrawing);
        colorPicker.addEventListener('input', changeColor);

        function changeColor() {
            context.strokeStyle = colorPicker.value;
        }

        function startDrawing(event) {
            initialDrawTime = Date.now();
            coordinates = [];
            drawing = true;
            context.beginPath();
            context.moveTo(event.offsetX, event.offsetY);
        }

        function draw(event) {
            if (!drawing) return;

            context.lineTo(event.offsetX, event.offsetY);
            context.stroke();

            coordinates.push([event.offsetX, event.offsetY]);
        }

        function stopDrawing() {
            if (!drawing) return;

            finalDrawTime = Date.now();
            drawing = false;
            context.closePath();
            let timeDiff = finalDrawTime - initialDrawTime;
            colorPicker.setAttribute('value', context.strokeStyle);

            SELF.pushEvent('drawClientToServer', { 
                coordinates: coordinates, 
                color: context.strokeStyle,
                time_diff: timeDiff,
                game_code: gameCode,
                player_id: playerId
            });
        }
    },
    updated() {
        const canvas = document.getElementById('drawingCanvas');
        if (!canvas) {
            return;
        }

        // const playerId = document.getElementById('player_id').value;
        const gamePlayLiveDiv = document.getElementById('game-play-live');
        const lastUpdateJson = gamePlayLiveDiv.getAttribute('data-last-update');
        const parsedObject = JSON.parse(lastUpdateJson);
        if (parsedObject.player_id === playerId) {
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
    }
}