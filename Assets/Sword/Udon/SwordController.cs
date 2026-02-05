using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class SwordController : UdonSharpBehaviour
{
	#region Fields
	[Tooltip("我们要追踪的目标")]
	public Transform target;
	[Tooltip("驱动【速度】CRT 的材质")]
	public Material crtVelMaterial;
	[Tooltip("速度 CRT 资源")]
	public CustomRenderTexture crtVel;
	[Tooltip("位置 CRT 资源")]
	public CustomRenderTexture crtPos;
	private int _targetPosID;
	#endregion

	#region UnityCallbacks
	private void Start()
	{
		_targetPosID = VRCShader.PropertyToID("_TargetPos");
	}

	private void Update()
	{
		if(target == null || crtVelMaterial == null || crtVel == null || crtPos == null) return;
		Transform origin = transform.parent != null ? transform.parent : transform;
		Vector3 localTargetPos = origin.InverseTransformPoint(target.position);
		crtVelMaterial.SetVector(_targetPosID, new Vector4(localTargetPos.x, localTargetPos.y, localTargetPos.z, 1f));
		crtVel.Update();
		crtPos.Update();
	}
	#endregion
}