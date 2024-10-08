export const InitializeCanvas = {
    mounted() {
        let SELF = this;
        const canvas = document.getElementById('drawingCanvas');
        if (!canvas) {
            return;
        }

        console.log('Canvas script loaded');

        const context = canvas.getContext('2d');
        let drawing = false;
        const colorPicker = document.getElementById('colorPicker');
        const gameCode = document.getElementById('game_code').value;
        let coordinates = [];

        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', draw);
        canvas.addEventListener('mouseup', stopDrawing);
        canvas.addEventListener('mouseout', stopDrawing);
        colorPicker.addEventListener('input', changeColor);

        function changeColor() {
            context.strokeStyle = colorPicker.value;
        }

        function startDrawing(event) {
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

            drawing = false;
            context.closePath();

            SELF.pushEvent('drawClientToServer', { 
                coordinates: coordinates, 
                color: colorPicker.value,
                game_code: gameCode
            });
        }

        function exportDrawing() {
            const dataURL = canvas.toDataURL('image/png');
            const link = document.createElement('a');
            link.href = dataURL;
            link.download = 'canvas-drawing.png';
            link.click();
        }
    },
    updated() {
        const gamePlayLiveDiv = document.getElementById('game-play-live');
        const lastUpdateJson = gamePlayLiveDiv.getAttribute('data-last-update');

        const parsedObject = JSON.parse(lastUpdateJson);
        console.log(parsedObject.color); // Outputs: #000000
        console.log(parsedObject.coordinates); // Outputs: the array of coordinates
    }
}