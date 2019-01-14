#!/bin/sh

erl -compile utils
erl -compile drawingTools
erl -compile lights
erl -noshell -s lights main -s init stop
