'use strict'; 
const express = require('express'); 
const bodyParser = require('body-parser'); 
const validator = require("email-validator");
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const app = express(); 
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({ extended: true })); 
const server = app.listen(8888, () => { console.log('Express server   listening on port %d in %s mode', server.address().port,   app.settings.env);});

const regex = new RegExp('[a-zA-Z -]+');
process.on('uncaughtException', function (err) {
  console.log(err);
});

app.post('/', (req, res) => { 
    const responseUrl = req.body.response_url;
    if(!req.body.token || !req.body.token.match(/^[0-9a-zA-Z]+$/) || req.body.token != process.env.SLACKTOKEN){
	res.send('401');
	return
    }
    if(req.body.channel_id != process.env.SOC2SLACKCHANNELID){
	res.send('This command is only available on the Compliance-soc-2 channel');
	return
    }
    if(!req.body.text){
        res.send('Sorry, wut? Ask me like "/soc2 companyname email"');
	return
    }
    let text = req.body.text.split(' '); 
    let response = '';
    if(text.length <2){
        res.send('Sorry, wut? Ask me like "/soc2 companyname email"');
    }
    let email = text[text.length-1];
    text.pop();
    let companyName = text.join(" ");
    if(validator.validate(email) && companyName.match(/^[0-9a-zA-Z \-]+$/)){
        response =  "*Generating SOC2* for: \n"+
        "Company: "+companyName+"\n"+
        "email: "+email+"\n";
        if(companyName.length + email.length > 40){
		res.send("Sorry, company Name and email together are too long. Please keep it below 40 characters");
	} else {
		makeReport(companyName, email, responseUrl).then((output) => {
           		sendDelayedResponse(output.responseUrl, output.body);
        	});
        	res.send({'response_type':'in_channel', 'text':req.body.user_name+' - Generating report for '+email+' at company '+companyName});
		//logRequestInSoc2Channel(req.body.user_name + " generated a SOC2 report for " + email + " at company " + companyName);
	}
    } else {
        response = "This info doesn't look right....aborting. Let's stick to valid emails, "+
        "simple letters, numbers and maaaaybe hyphens";
        res.send(response)
    }    
  });

const makeReport = async (companyName, email, responseUrl) => {
            try{
                await generateReport(companyName, email);
                let result = await getPwdAndLink(companyName);
                return {responseUrl: responseUrl, body: result};
            } catch(err) {
                console.error(err);
            }
    
}

const generateReport = async (companyName, email) => {
        let shellCommand = 'cd /workdir && sh soc2-generate-and-upload.sh '+companyName+' '+email;
console.log(shellCommand);
        try{
            const stdout = await execCmd(shellCommand);
            return stdout;
        } catch(err){
            console.error(err);
        }
}

const getPwdAndLink = async (companyName) => {
        let shellCommand = 'cd /workdir && sh soc-read-and-cleanup.sh Snyk-SOC2-'+companyName.toUpperCase()+'.pdf';
console.log(shellCommand);
        try{
            const stdout = await execCmd(shellCommand);
            return stdout;
        } catch(err){
            console.error(err);
        }
}


async function execCmd (shellCommand) {
    try{
        const { stdout, stderr } = await exec(shellCommand);
        return stdout;
    } catch(err){
        console.error(err);
    };
        
    
}

const sendDelayedResponse = (responseUrl, body) => {
    const axios = require('axios');
    let textContent = 'Link => '+body.split('\n')[2]+'\nPassword => '+body.split('\n')[0];
    let responseBody = {
        "text": textContent,
    }
    let headers = {
        'Content-Type': 'application/json'
    }
    console.log(responseUrl);
    axios.post(responseUrl, JSON.stringify(responseBody), {headers: headers})
    .then((res) => {
      console.log('Report link and password sent');
    })
    .catch((error) => {
      console.error(error)
    })}



const logRequestInSoc2Channel = (message) => {
	 const axios = require('axios');
    let responseBody = {
    }
    let headers = {
        'Content-Type': 'application/json'
    }
    let urlChat='https://slack.com/api/chat.postMessage?token='+process.env.SLACKOAUTHTOKEN+'&channel='+soc2Channel+'&text='+message;
    axios.post(urlChat, JSON.stringify(responseBody), {headers: headers})
    .then((res) => {
    console.log('Logged '+message+ ' at '+Date.now())
    })
    .catch((error) => {
    console.error(error)
    })

}
