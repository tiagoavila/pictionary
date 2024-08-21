window.onload = function() {
    console.log('Canvas script loaded');
    const canvas = document.getElementById('drawingCanvas');
    if (!canvas) {
        return;
    }

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
        channel.push('ping', {page: '3'})
    }

    function exportDrawing() {
        const dataURL = canvas.toDataURL('image/png');
        const link = document.createElement('a');
        link.href = dataURL;
        link.download = 'canvas-drawing.png';
        link.click();
    }
};