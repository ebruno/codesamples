 curl -H 'Content-Type: application/json' \
   -d '{ "person": { "id": "123", "name": "John Doe", "address": { "street": "123 Main St", "city": "Anytown","zip": "12345" }, "phoneNumbers": [ { "type": "home", "number": "555-1234" }, {"type": "mobile", "number": "555-5678" } ] } }' \
 -X POST http://localhost:5001/ebprettify


 curl -H 'Content-Type: application/text' \
      -d '{"xxx": 5}' \
 -X POST http://localhost:5001/ebprettify
