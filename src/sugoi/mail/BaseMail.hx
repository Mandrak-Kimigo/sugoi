package sugoi.mail;

/**
 * abstract class to extend
 */
class BaseMail implements IMail
{
	public var title : String;
	public var htmlBody : String;
	public var textBody : String;
	var senderName : String;
	var senderEmail : String;
	var recipients : Array<{name:String,email:String,?userId:Int}>;
	var headers : Map<String,String>;
	
	public function new() {
		recipients = [];
		headers = new Map();
	}
	
	public function setSender(email, ?name) {
		if(!isValid(email)) throw "invalid sender \""+email+"\"";
		senderEmail = email;
		name == null?senderName = senderEmail:senderName = name;
	}
	
	public function setSubject(s:String) {
		title = s;
	}
	
	
	/**
	 * can add one or more recipient
	 * @param	email
	 * @param	?name
	 * @param	?userId
	 */
	public function addRecipient(email:String, ?name:String, ?userId:Int) {
		if(!isValid(email)) throw "invalid recipient \""+email+"\"";
		//recipientEmail = email;
		//name == null?recipientName = recipientEmail:recipientName = name;
		//recipientUserId = userId;
		recipients.push( {email:email,name:name,userId:userId } );
	}
	
	/**
	 * alias to addRecipient()
	 * @param	email
	 * @param	?name
	 * @param	?userId
	 */
	public function setRecipient(email:String, ?name:String, ?userId:Int) {
		addRecipient(email, name, userId);
	}
	
	public static function isValid( addr : String ){
		var reg = ~/^[^()<>@,;:\\"\[\]\s[:cntrl:]]+@[A-Z0-9][A-Z0-9-]*(\.[A-Z0-9][A-Z0-9-]*)*\.(xn--[A-Z0-9]+|[A-Z]{2,8})$/i;
		return addr != null && reg.match(addr);
	}
	
	public function setHeader(k:String, v:String) {
		headers.set(k, v);
	}
	
	/**
	 * generate a custom key for transactionnal emails, valid during the current day
	 */
	public function getKey() {
		return haxe.crypto.Md5.encode(App.App.config.get("key")+recipients[0].email+(Date.now().getDate())).substr(0,12);
	}
	
	/**
	 * render html from a template + vars
	 * @param	tpl		A Template path
	 * @param	ctx 	Vars to send to template
	 */
	public function setHtmlBody(tpl, ctx:Dynamic) {
		#if twinBase
		var app = App.current;
		var tpl = app.loadTemplate(tpl);
		if( ctx == null ) ctx = { };
		ctx.HOST = App.App.config.HOST;
		ctx.key = getKey();
		ctx.senderName = senderName;
		ctx.senderEmail = senderEmail;
		ctx.recipientName = recipients[0].name;
		ctx.recipientEmail = recipients[0].email;
		ctx.recipients = recipients;
		CSSInlining(ctx);
		htmlBody = tpl.execute(ctx);
		#else
		throw "cannot use this method";
		#end
	}
	
	public function setTextBody(tpl, ctx:Dynamic) {
		#if twinBase
		var app = App.current;
		var tpl = app.loadTemplate(tpl);
		if( ctx == null ) ctx = { };
		ctx.HOST = App.config.HOST;
		ctx.key = getKey();
		textBody = tpl.execute(ctx);
		#else
		throw "cannot use this method";
		#end
	}
	
	
	
	public function send() {
		throw "not implemented";
	}
	
	function CSSInlining(ctx) {
		// CSS inlining
		var css : Map<String,Array<String>> = new Map();
		ctx.addStyle = function(sel:String, style:String) {
			sel = sel.toLowerCase();
			if (css.exists(sel))
				css.set(sel, css.get(sel).concat(style.split(";")));
			else
				css.set(sel, style.split(";"));
			return "";
		}
		var applyStyleRec = null;
		applyStyleRec = function(x:Xml) {
			if (x.nodeType==Xml.Element) {
				var name = x.nodeName.toLowerCase();
				if( css.exists(name) )
					if (x.get("style")!=null)
						x.set("style", x.get("style")+";"+css.get(name).join(";"));
					else
						x.set("style", css.get(name).join(";"));
				for (n in x)
					applyStyleRec(n);
			}
		}
		ctx.applyStyle = function(raw:String) {
			var x = Xml.parse(raw);
			for(n in x)
				applyStyleRec(n);
			return x.toString();
		}
	}
	
}