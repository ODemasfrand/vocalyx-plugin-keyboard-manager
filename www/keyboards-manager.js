var exec = require('cordova/exec');

var KeyboardFolder = require('./KeyboardFolder');

var KeyboardsManager = {};

KeyboardsManager.listEmbeddedKeyboards = function(){
	return new Promise(function(resolve, reject){
		exec(success, reject, 'KeyboardsManager', 'listEmbeddedKeyboards', []);

		function success(result){
			if(device.platform == 'iOS')
				result = result
					.map(decode)
					.map(JSON.parse);

			resolve(result);
		}
	});
};

KeyboardsManager.installEmbeddedKeyboard = function(keyboard){
	return new Promise(function(resolve, reject){
		exec(resolve, reject, 'KeyboardsManager', 'installEmbedded', [keyboard.fileName, keyboard.folder.slug])
	});
};

KeyboardsManager.installKeyboard = function(keyboard){
	return new Promise(function(resolve, reject){
		exec(resolve, reject, 'KeyboardsManager', 'install', [keyboard.fileName, keyboard.folder.slug])
	});
};

KeyboardsManager.zipKeyboard = function(keyboardSlug){
	return new Promise(function(resolve, reject){
		exec(resolve, reject, 'KeyboardsManager', 'zipKeyboard', [keyboardSlug])
	});
};

KeyboardsManager.parseKeyboardZip = function(keyboardName, downloadUrl){
	return new Promise(function(resolve, reject){
		exec(success, reject, 'KeyboardsManager', 'parseKeyboardZip', [keyboardName, downloadUrl]);

		function success(result){
			if(device.platform == 'iOS'){
				result = JSON.parse(decode(result));

				if (result.extras)
					result.extras = JSON.parse(decode(result.extras));
			}
			
			resolve(result);
		}
	});
};

function decode(string){
	return decodeURIComponent(escape(string));
}

KeyboardsManager.KeyboardFolder = KeyboardFolder;

module.exports = KeyboardsManager;
