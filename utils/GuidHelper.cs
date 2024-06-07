using Godot;
using System;

[GlobalClass]
public partial class GuidHelper: Node
{
	public static string GenerateGuid(){
		return Guid.NewGuid().ToString();
	}
}
