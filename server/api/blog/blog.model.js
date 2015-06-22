'use strict';

var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var BlogSchema = new Schema({
    title: String,
    body: String,
    date: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Blog', BlogSchema);