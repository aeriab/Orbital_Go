using Godot;
using System.Collections.Generic;
using Godot.Collections;

public partial class CaptureManager : Node
{
    private Node _global;
    private Node _stoneManager;

    [Export] public float CheckInterval = 0.2f;
    private float _timer = 0.0f;

    public override void _Ready()
    {
        // Cache our Autoloads for quick access
        _global = GetNode("/root/Global");
        _stoneManager = GetNode("/root/StoneManager");
    }

    public override void _PhysicsProcess(double delta)
    {
        _timer += (float)delta;
        if (_timer >= CheckInterval)
        {
            _timer = 0.0f;
            RunGameLogic();
        }
    }

    private void RunGameLogic()
    {
        // Step 1: Update the real-time territory score
        UpdateTerritoryScore();

        // Step 2: Detect Loops (The Graph/Geometry logic)
        // We will implement the DFS loop detection here next
        DetectAndProcessCaptures();
    }

    private void UpdateTerritoryScore()
    {
        // This is where we put the logic to count stones inside the zone
        var stones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        float zoneRadius = (float)_global.Get("zone_radius");
        float radiusSq = zoneRadius * zoneRadius;

        float p1Current = 0;
        float p2Current = 0.5f; // Komi for white

        foreach (var stone in stones)
        {
            if (!IsInstanceValid(stone)) continue;

            if (stone.GlobalPosition.LengthSquared() <= radiusSq)
            {
                if (stone.IsInGroup("P1")) p1Current += 1;
                if (stone.IsInGroup("P2")) p2Current += 1;
            }
        }

        // Update Global values (which triggers the UI signals)
        _global.Set("p1_score", p1Current);
        _global.Set("p2_score", p2Current);
        _global.EmitSignal("score_updated", p1Current, p2Current);
    }

    private void DetectAndProcessCaptures()
    {
        // Placeholder for the Graph-based loop detection
        // This is where the heavy computational geometry happens
    }
}