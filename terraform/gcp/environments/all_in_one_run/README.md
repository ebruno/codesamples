# Build Control #
There is current no default set for the cur\_env (Current Environment) variable.
You can can set the TF\_VAR\_cur_env variable to one of the following:

 - prod : production
 - qa   : Quality Assurance 
 - dev  : Development
 
 or 
  use the option -var
  
        teraform apply|destroy -var="cur_env=[dev|qa|prod]"
