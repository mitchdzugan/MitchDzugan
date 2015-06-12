'use strict';

var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var BlogSchema = new Schema({
    title: String,
    body: String,
    image: String,
    date: { type: Date, default: Date.now },
    comments: [{
        author: String,
        body: String,
        date: Date
    }]
});

module.exports = mongoose.model('Blog', BlogSchema);