# Use the official Nginx image as the base
FROM nginx:latest

# Copy your website content into the Nginx web root directory
# Replace './html' with the path to your static website files on your local machine
COPY ./web_server/html /usr/share/nginx/html

# Expose port 80, which is the default port for Nginx
EXPOSE 80

# Command to run Nginx in the foreground when the container starts
#CMD ["nginx", "-g", "daemon off;"]
