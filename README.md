Welcome to your new dbt project!  

### Using the starter project  

Try running the following commands:  
- dbt run  
- dbt test  
  
  
### Resources:  
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)  
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers  
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support  
- Find [dbt events](https://events.getdbt.com) near you  
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices  
  

### Steps
**1- create a virutal environment**  
python -m venv dbt-env              # create the environment  

**2- activate the virtual environment**  
dbt-env\Scripts\activate            # activate the environment for Windows  

**3- install dbt and postgres adaptor**   
python -m pip install dbt-core dbt-postgres  

**4- validate installation**  
dbt --version  

**5- initialize a dbt project and follow the prompt**   
dbt init  

**6- create the profile.yml file in the project directory or the user's home directory and setup the db connection**   
-- new file in vscode  
-- paste the following  
```  
my_dbt_demo:  
  outputs:   
    my_dev_db:  
      type: postgres  
      host: localhost  
      port: 5432  
      user: sample_user  
      pass: ${DB_PASSWORD}  
      dbname: new_sample_db  
      schema: dev  
      threads: 1  
        
    my_prod_db:  
      type: postgres  
      host: localhost  
      port: 5432  
      user: sample_user  
      pass: ${DB_PASSWORD}  
      dbname: new_sample_db  
      schema: prod  
      threads: 1  
```  
  
**7- encrypt password**   
$env:DB_PASSWORD = "sample_password"  
echo $env:DB_PASSWORD  
-- change password to ${DB_PASSWORD} in profiles.yml  
  
**8- test connection**   
dbt debug --target my_dev_db  
dbt debug --target my_prod_db  
  
### git commands  
echo "# dbt-demo" >> README.md  
git init  
git add README.md  
git commit -m "first commit"  
git branch -M main  
git remote add origin https://github.com/msonbol-afiniti/dbt-demo.git  
git push -u origin main  
  

### dbt commands  
dbt build  
dbt test  
dbt run  
dbt docs generate  
dbt docs serve  
