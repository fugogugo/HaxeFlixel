package addons;
import nme.geom.Matrix;
import org.flixel.FlxBasic;
import org.flixel.FlxCamera;
import org.flixel.FlxG;
import org.flixel.FlxPoint;
import org.flixel.FlxSprite;

/**
 * ...
 * @author Zaphod
 */

class FlxSkewedSprite extends FlxSprite
{

	public var skew:FlxPoint;
	private var _skewMatrix:Matrix;
	
	public function new() 
	{
		super();
		
		skew = new FlxPoint();
		_skewMatrix = new Matrix();
	}
	
	override public function destroy():Void 
	{
		skew = null;
		_skewMatrix = null;
		
		super.destroy();
	}
	
	override public function getSimpleRender():Bool
	{ 
		return (((angle == 0) || (_bakedRotation > 0)) && (scale.x == 1) && (scale.y == 1) && (blend == null) && (skew.x == 0) && (skew.y == 0));
	}
	
	// TODO: Implement skewing
	override public function draw():Void 
	{
		if(_flickerTimer != 0)
		{
			_flicker = !_flicker;
			if (_flicker)
			{
				return;
			}
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
		if (cameras == null)
		{
			cameras = FlxG.cameras;
		}
		var camera:FlxCamera;
		var i:Int = 0;
		var l:Int = cameras.length;
		
		#if (cpp || neko)
		var currDrawData:Array<Float>;
		var currIndex:Int;
		
		var radians:Float;
		var cos:Float;
		var sin:Float;
		#end
		
		while(i < l)
		{
			camera = cameras[i++];
			
			if (!onScreen(camera))
			{
				continue;
			}
			_point.x = x - Math.floor(camera.scroll.x * scrollFactor.x) - Math.floor(offset.x);
			_point.y = y - Math.floor(camera.scroll.y * scrollFactor.y) - Math.floor(offset.y);
			
			#if (cpp || neko)
			currDrawData = _tileSheetData.drawData[camera.ID];
			currIndex = _tileSheetData.positionData[camera.ID];
			
			_point.x = Math.floor(_point.x) + origin.x;
			_point.y = Math.floor(_point.y) + origin.y;
			#else
			_point.x += (_point.x > 0)?0.0000001:-0.0000001;
			_point.y += (_point.y > 0)?0.0000001: -0.0000001;
			#end
			if (simpleRender)
			{	//Simple render
				#if flash
				_flashPoint.x = _point.x;
				_flashPoint.y = _point.y;
				camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
				#else
				currDrawData[currIndex++] = _point.x;
				currDrawData[currIndex++] = _point.y;
				
				currDrawData[currIndex++] = _frameID;
				
				// handle reversed sprites
				if ((_flipped != 0) && (_facing == FlxObject.LEFT))
				{
					currDrawData[currIndex++] = -1;
					currDrawData[currIndex++] = 0;
					currDrawData[currIndex++] = 0;
					currDrawData[currIndex++] = 1;
				}
				else
				{
					currDrawData[currIndex++] = 1;
					currDrawData[currIndex++] = 0;
					currDrawData[currIndex++] = 0;
					currDrawData[currIndex++] = 1;
				}
				
				if (_tileSheetData.isColored || camera.isColored)
				{
					if (camera.isColored)
					{
						currDrawData[currIndex++] = _red * camera.red; 
						currDrawData[currIndex++] = _green * camera.green;
						currDrawData[currIndex++] = _blue * camera.blue;
					}
					else
					{
						currDrawData[currIndex++] = _red; 
						currDrawData[currIndex++] = _green;
						currDrawData[currIndex++] = _blue;
					}
				}
				
				currDrawData[currIndex++] = _alpha;
				
				_tileSheetData.positionData[camera.ID] = currIndex;
				#end
			}
			else
			{	//Advanced render
				#if flash
				_matrix.identity();
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				if ((angle != 0) && (_bakedRotation <= 0))
				{
					_matrix.rotate(angle * 0.017453293);
				}
				
				if (skew.x != 0 || skew.y != 0)
				{
					_skewMatrix.identity();
					_skewMatrix.b = Math.tan(skew.x * 0.017453293);
					_skewMatrix.c = Math.tan(skew.y * 0.017453293);
					
					_matrix.concat(_skewMatrix);
				}
				
				_matrix.translate(_point.x + origin.x, _point.y + origin.y);
				camera.buffer.draw(framePixels, _matrix, null, blend, null, antialiasing);
				#else
				radians = -angle * 0.017453293;
				cos = Math.cos(radians);
				sin = Math.sin(radians);
				
				currDrawData[currIndex++] = _point.x;
				currDrawData[currIndex++] = _point.y;
				
				currDrawData[currIndex++] = _frameID;
				
				if ((_flipped != 0) && (_facing == FlxObject.LEFT))
				{
					currDrawData[currIndex++] = -cos * scale.x;
					currDrawData[currIndex++] = sin * scale.y;
					currDrawData[currIndex++] = -sin * scale.x;
					currDrawData[currIndex++] = cos * scale.y;
				}
				else
				{
					currDrawData[currIndex++] = cos * scale.x;
					currDrawData[currIndex++] = sin * scale.y;
					currDrawData[currIndex++] = -sin * scale.x;
					currDrawData[currIndex++] = cos * scale.y;
				}
				
				if (_tileSheetData.isColored || camera.isColored)
				{
					if (camera.isColored)
					{
						currDrawData[currIndex++] = _red * camera.red; 
						currDrawData[currIndex++] = _green * camera.green;
						currDrawData[currIndex++] = _blue * camera.blue;
					}
					else
					{
						currDrawData[currIndex++] = _red; 
						currDrawData[currIndex++] = _green;
						currDrawData[currIndex++] = _blue;
					}
				}
				
				currDrawData[currIndex++] = _alpha;
				
				_tileSheetData.positionData[camera.ID] = currIndex;
				#end
			}
			FlxBasic._VISIBLECOUNT++;
			if (FlxG.visualDebug && !ignoreDrawDebug)
			{
				drawDebug(camera);
			}
		}
	}
	
}