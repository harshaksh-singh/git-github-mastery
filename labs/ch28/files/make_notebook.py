#!/usr/bin/env python3
"""Write the error-analysis notebook as Jupyter would save it after run number N.

A stand-in for running the notebook: the cell sources are the same on every run; the
execution counts, the printed output and the embedded chart differ, as they do in real use.
Usage: python3 make_notebook.py N > notebook.ipynb
"""
import base64
import json
import sys

run = int(sys.argv[1])
chart = base64.b64encode(bytes((i * run) % 251 for i in range(1500))).decode()


def code(cell_id, count, source, outputs):
    return {"cell_type": "code", "execution_count": count, "id": cell_id,
            "metadata": {}, "outputs": outputs, "source": source}


cells = [
    {"cell_type": "markdown", "id": "intro", "metadata": {},
     "source": ["# Error analysis for the ticket classifier"]},
    code("load", 3 * run + 1,
         ["import os\n", "key = os.environ[\"LLM_API_KEY\"]\n", "print(\"using key\", key)"],
         [{"name": "stdout", "output_type": "stream",
           "text": ["using key sk-demo-not-a-real-key-%04d\n" % run]}]),
    code("errors", 3 * run + 2,
         ["errors = evaluate(\"data/raw/tickets.csv\")\n", "errors.head()"],
         [{"data": {"text/plain": ["   text                        gold     pred\n",
                                   "0  card charged twice, a...    billing  general\n"]},
           "execution_count": 3 * run + 2, "metadata": {}, "output_type": "execute_result"}]),
    code("chart", 3 * run + 3, ["plot_confusion(errors)"],
         [{"data": {"image/png": chart, "text/plain": ["<Figure size 640x480 with 1 Axes>"]},
           "metadata": {}, "output_type": "display_data"}]),
]
nb = {"cells": cells,
      "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                   "language_info": {"name": "python"}},
      "nbformat": 4, "nbformat_minor": 5}
sys.stdout.write(json.dumps(nb, indent=1, ensure_ascii=False) + "\n")
