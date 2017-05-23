var exec = require('cordova/exec');

var WORDS_REGEXP = /[\w]+/g;
var CONSIDERED_AS_WHITESPACE_REGEXP = /[\s\-\_]+/g;
var WHITESPACE_SEPARATOR = '_';
var IMAGE_PREFIX = 'image';
var SOUND_PREFIX = 'sound';

var ANDROID_ROOT_DIRECTORY_NAME = 'files';
var IOS_ROOT_DIRECTORY_NAME = 'documents';

KeyboardFolder.slugify = function(str){
	if (!str)
		return '';

	var words = str.match(WORDS_REGEXP) || [];
	return words.join('')
		.replace(CONSIDERED_AS_WHITESPACE_REGEXP, WHITESPACE_SEPARATOR);
};

KeyboardFolder.fromObject = function(keyboardFolderObject){
	return new KeyboardFolder(keyboardFolderObject._name, keyboardFolderObject._slug);
};

KeyboardFolder.fromName = function(name){
	return new KeyboardFolder(name);
};

function KeyboardFolder(name, slug) {
	var _this = this;
	this._name = name;
	this._slug = (slug)? slug : KeyboardFolder.slugify(name);
	this._getSize()
		.then(setSize);
	setRootDirectoryName();

	function setSize(result){
		_this._size = result;
	}

	function setRootDirectoryName(){
		if(device.platform == 'Android')
			_this._rootDirectoryName = ANDROID_ROOT_DIRECTORY_NAME;

		if(device.platform == 'iOS')
			_this._rootDirectoryName = IOS_ROOT_DIRECTORY_NAME;
	}
}

KeyboardFolder.prototype = {
	_name: undefined,
	get name() {
		return this._name;
	},

	_slug: undefined,
	get slug(){
		return this._slug;
	},

	_rootDirectoryName: undefined,

	_initPromise: undefined,
	_temp: undefined,
	_folder: undefined,
	_images: undefined,
	_sounds: undefined,
	_size: undefined,
	get size(){
		return this._size;
	}
};

KeyboardFolder.prototype.init = function(){
	var _this = this;
	if (this._initPromise)
		return this._initPromise;

	return this._initPromise = this._getRoot()
		.tap(getTempFolder)
		.then(getFolder)
		.then(getSubFolders)
		.return(this);


	function getTempFolder(root){
		return new Promise(function(resolve, reject){
			return root.getDirectory('temp', { create: true }, resolve, reject);
		})
			.tap(setTempFolder);

		function setTempFolder(temp){
			_this._temp = temp;
		}
	}

	function getFolder(root){
		return new Promise(function(resolve, reject){
			root.getDirectory(_this._slug, { create: true },  resolve, reject);
		})
			.tap(setFolder);

		function setFolder(folder){
			_this._folder = folder;
		}
	}

	function getSubFolders(folder){
		return Promise.all([
			getSubFolder('images'),
			getSubFolder('sounds')
		])
			.spread(setSubFolders);

		function getSubFolder(subFolderName){
			return new Promise(function(resolve, reject){
				folder.getDirectory(subFolderName, { create: true }, resolve, reject);
			});
		}

		function setSubFolders(images, sounds){
			_this._images = images;
			_this._sounds = sounds;
		}
	}
};

KeyboardFolder.prototype.toImageUrl = function(fileName){
	return 'cdvfile://localhost/:rootDirectoryName/:slug/images/:fileName'
		.replace(':rootDirectoryName', this._rootDirectoryName || this._getRootDirectoryName())
		.replace(':slug', this._slug)
		.replace(':fileName', fileName);
};

KeyboardFolder.prototype.toSoundUrl = function(fileName){
	return 'cdvfile://localhost/:rootDirectoryName/:slug/sounds/:fileName'
		.replace(':rootDirectoryName', this._rootDirectoryName || this._getRootDirectoryName())
		.replace(':slug', this._slug)
		.replace(':fileName', fileName);
};

KeyboardFolder.prototype.copyImage = function(imageUri){
	if(!imageUri)
		return Promise.resolve();

	var _this = this;

	return Promise.all([
		this.init(),
		getImageFileEntry()
	])
		.spread(copy)
		.then(this._toImageFileNameAndUrl.bind(this));

	function getImageFileEntry(){
		return new Promise(function(resolve, reject){
			return resolveLocalFileSystemURL(imageUri, resolve, reject);
		});
	}

	function copy(folder, imageFileEntry){
		return new Promise(function(resolve, reject){
			imageFileEntry.copyTo(folder._images, _this._generateFileName(IMAGE_PREFIX, imageUri), resolve, reject);
		});
	}
};

KeyboardFolder.prototype.copySound = function(soundUri){
	if(!soundUri)
		return Promise.resolve();

	var _this = this;

	return Promise.all([
		this.init(),
		getSoundFileEntry()
	])
		.spread(copy)
		.then(this._toSoundFileNameAndUrl.bind(this));

	function getSoundFileEntry(){
		return new Promise(function(resolve, reject){
			return resolveLocalFileSystemURL(soundUri, resolve, reject);
		});
	}

	function copy(folder, soundFileEntry){
		return new Promise(function(resolve, reject){
			soundFileEntry.copyTo(folder._sounds, _this._generateFileName(SOUND_PREFIX, soundUri), resolve, reject);
		});
	}
};

KeyboardFolder.prototype.copyAssets = function(sourceFolderSlug){
	var targetFolderName = this.slug || sourceFolderSlug + '-copy';

	return this._getRoot()
		.tap(ensureDestinationDoesNotExist)
		.then(getSourceFolderEntry)
		.then(copyAssets);

	function ensureDestinationDoesNotExist(root){
		return new Promise(function(resolve, reject){
			root.getDirectory(targetFolderName, {},  resolve, reject)
		})
			.catch(resolve);

		function resolve(){
			return Promise.resolve();
		}
	}
	
	function getSourceFolderEntry(root){
		return new Promise(function(resolve, reject){
			root.getDirectory(sourceFolderSlug, {},  resolve, reject)
		});
	}

	function copyAssets(sourceFolder){
		return new Promise(function(resolve, reject) {
			sourceFolder.copyTo(sourceFolder.filesystem.root, targetFolderName, resolve, reject);
		});
	}
};

KeyboardFolder.prototype.moveSound = function(soundName){
	var _this = this;

	return this.init()
		.then(getSoundFileEntry)
		.then(move)
		.then(this._toSoundFileNameAndUrl.bind(this));

	function getSoundFileEntry(){
		return new Promise(function(resolve, reject){
			_this._temp.getFile(soundName, {}, resolve, reject);
		});
	}

	function move(soundFileEntry){
		return new Promise(function(resolve, reject){
			soundFileEntry.moveTo(_this._sounds, _this._generateFileName(SOUND_PREFIX, '.wav'), resolve, reject);
		});
	}
};

KeyboardFolder.prototype.removeSound = function(soundName){
	if(!soundName)
		return Promise.resolve();
	
	var _this = this;

	return this.init()
		.then(getSoundFileEntry)
		.then(remove);

	function getSoundFileEntry(){
		return new Promise(function(resolve, reject){
			_this._sounds.getFile(soundName, {}, resolve, reject);
		});
	}

	function remove(soundFileEntry){
		return new Promise(function(resolve, reject){
			soundFileEntry.remove(resolve, reject);
		});
	}
};

KeyboardFolder.prototype.removeImage = function(imageName){
	if(!imageName)
		return Promise.resolve();

	var _this = this;

	return this.init()
		.then(getImageFileEntry)
		.then(remove);

	function getImageFileEntry(){
		return new Promise(function(resolve, reject){
			_this._images.getFile(imageName, {}, resolve, reject);
		});
	}

	function remove(imageFileEntry){
		return new Promise(function(resolve, reject){
			imageFileEntry.remove(resolve, reject);
		});
	}
};

KeyboardFolder.prototype.removeSoundAndImage = function(soundName, imageName){
	return this.removeImage(imageName)
		.then(this.removeSound.bind(this, soundName));
};

KeyboardFolder.prototype.removeFolder = function(){
	var _this = this;
	return this.init()
		.then(removeFilesFolder);

	function removeFilesFolder(){
		return new Promise(function(resolve, reject){
			_this._folder.removeRecursively(resolve, reject);
		});
	}
};

KeyboardFolder.prototype.toJSON = function(){
	return {
		_name: this._name,
		_slug: this._slug
	};
};

KeyboardFolder.prototype._getRoot = function(){
	return new Promise(function(resolve, reject){
		var rootPath = undefined;

		if(device.platform == 'Android')
			rootPath = cordova.file.dataDirectory;

		if(device.platform == 'iOS')
			rootPath = cordova.file.documentsDirectory;

		resolveLocalFileSystemURL(rootPath, resolve, reject);
	});
};

KeyboardFolder.prototype._getRootDirectoryName = function(){
	if(device.platform == 'Android')
		return ANDROID_ROOT_DIRECTORY_NAME;

	if(device.platform == 'iOS')
		return IOS_ROOT_DIRECTORY_NAME;
};

KeyboardFolder.prototype._generateFileName = function(prefix, extensionString){
	var fileName =  ':prefix-:timestamp'
		.replace(':prefix', prefix)
		.replace(':timestamp', Date.now().toString());

	var extension = (extensionString && extensionString.indexOf('.') != -1)? extensionString.substring(extensionString.lastIndexOf('.')) : undefined;
	if(extension)
		fileName += extension;

	return fileName;
};

KeyboardFolder.prototype._toImageFileNameAndUrl = function(file){
	return {
		name: file.name,
		url: this.toImageUrl(file.name)
	};
};

KeyboardFolder.prototype._toSoundFileNameAndUrl = function(file){
	return {
		name: file.name,
		url: this.toSoundUrl(file.name)
	};
};

KeyboardFolder.prototype._getSize = function () {
	var slug = this.slug;
	return new Promise(function (resolve, reject) {
		exec(resolve, reject, 'KeyboardsManager', 'getFolderSize', [ slug ]);
	});
};

module.exports = KeyboardFolder;
