package tink.macro;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	
	using tink.macro.Positions;
	using tink.macro.Exprs;
#end
@:exclude class Bouncer {
	#if macro
		static var idCounter = 0;
		static var bounceMap = new Map<Int,Void->Expr>();
		static var outerMap = new Map<Int,Expr->Expr>();
		static public function bounce(f:Void->Expr, ?pos) {
			var id = idCounter++;
			bounceMap.set(id, f);
			return 'tink.macro.Bouncer.catchBounce'.resolve(pos).call([id.toExpr(pos)], pos);
		}
		static public function outerTransform(e:Expr, transform:Expr->Expr) {
			var id = idCounter++,
				pos = e.pos;
			outerMap.set(id, transform);
			return 'tink.macro.Bouncer.makeOuter'.resolve(pos).call([e], pos).field('andBounce', pos).call([id.toExpr(pos)], pos);
		}		
		static function doOuter(id:Int, e:Expr) {
			return
				if (outerMap.exists(id)) 
					outerMap.get(id)(e);
				else
					Context.currentPos().error('unknown id ' + id);	
		}
		static function doBounce(id:Int) {
			return
				if (bounceMap.exists(id)) 
					bounceMap.get(id)();
				else
					Context.currentPos().error('unknown id ' + id);	
		}
	#else
	static public function makeOuter<A>(a:A):Bouncer 
		return null;
	#end
	macro public function andBounce(ethis:Expr, id:Int) {
		return
			switch (ethis.expr) {
				case ECall(_, params): doOuter(id, params[0]);
				default: ethis.reject();
			}
	}
	macro static public function catchBounce(id:Int) {
		return doBounce(id);
	}
}