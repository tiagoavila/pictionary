import socket from "./user_socket";

export const SomeFunction = {
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
        const exportCheckbox = document.getElementById('exportCheckbox');
        let coordinates = [];

        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', draw);
        canvas.addEventListener('mouseup', stopDrawing);
        canvas.addEventListener('mouseout', stopDrawing);
        colorPicker.addEventListener('input', changeColor);

        let channel = socket.channel("draw_updates:lobby", {})
        channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) })

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

            if (exportCheckbox.checked === true) {
                exportDrawing();
            }

            console.log(coordinates);

            channel.push('ping', { tiago: 'ping' })

            SELF.pushEvent('pong', { simone: 'pong' })
        }

        function exportDrawing() {
            const dataURL = canvas.toDataURL('image/png');
            const link = document.createElement('a');
            link.href = dataURL;
            link.download = 'canvas-drawing.png';
            link.click();
        }
    }
}