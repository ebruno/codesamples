from flask import Flask, request, jsonify
import json

app = Flask(__name__)

#app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True
app.json.compact = False

@app.route('/ebprettify', methods=['POST'])
def prettify_json():
    try:
        data = request.get_json()
        if data is None:
            return jsonify({"error": "No JSON data in post request."}), 400
        
        # Ensure the output is pretty-printed
        return jsonify(data)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
    
