import express from 'express';

const app = express();

app.set('view engine', 'ejs');

app.get('/', (req, res) => {
    res.render('home');
});

app.post('/upload', (req, res) => {
    if (!req.files || Object.keys(req.files).length === 0) {
        return res.status(400).send('No files were uploaded.');
    }

    const file = req.files.file;
    const filePath = 'files/' + file.name;

    const title = req.body.title;
    const description = req.body.description;
    const address = req.body.address;

    
    
});

app.listen(3100, () => {
    console.log('Server is running on http://localhost:3100');
})