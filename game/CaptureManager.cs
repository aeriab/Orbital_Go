using Godot;
using System;
using System.Collections.Generic;
using Godot.Collections;

public partial class CaptureManager : Node2D
{
    private Node _global;
    private Node _stoneManager;

    [Export] public float CheckInterval = 0.2f;
    private float _timer = 0.0f;

    public override void _Ready()
    {
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

    public void UpdateTerritoryScore()
    {
        var stones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        float zoneRadius = (float)_global.Get("zone_radius");
        float radiusSq = zoneRadius * zoneRadius;

        float p1Current = 0;
        float p2Current = 0.5f; 

        foreach (var stone in stones)
        {
            if (!IsInstanceValid(stone)) continue;
            if (stone.GlobalPosition.LengthSquared() <= radiusSq)
            {
                if (stone.IsInGroup("P1")) p1Current += 1;
                if (stone.IsInGroup("P2")) p2Current += 1;
            }
        }

        _global.Set("p1_score", p1Current);
        _global.Set("p2_score", p2Current);
        _global.EmitSignal("score_updated", p1Current, p2Current);
    }

    private void RunGameLogic()
    {
        UpdateTerritoryScore();
        DetectAndProcessCaptures("P1", "P2"); // P1 creates loops to capture P2
        DetectAndProcessCaptures("P2", "P1"); // P2 creates loops to capture P1
    }

    private void DetectAndProcessCaptures(string team, string opponent)
    {
        var allStones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        var teamStones = new List<RigidBody2D>();
        var opponentStones = new List<RigidBody2D>();

        foreach (var s in allStones)
        {
            if (s.IsInGroup(team)) teamStones.Add(s);
            else if (s.IsInGroup(opponent)) opponentStones.Add(s);
        }

        if (teamStones.Count < 3) return; // Need at least 3 stones for a loop

        // 1. Build Adjacency Graph
        var adj = BuildAdjacency(teamStones);

        // 2. Find Cycles
        var cycles = FindCycles(teamStones, adj);

        // 3. Check for victims in each cycle
        var capturedStones = new HashSet<RigidBody2D>();
        foreach (var cycle in cycles)
        {
            Vector2[] polygon = new Vector2[cycle.Count];
            for (int i = 0; i < cycle.Count; i++) polygon[i] = cycle[i].GlobalPosition;

            foreach (var victim in opponentStones)
            {
                if (Geometry2D.IsPointInPolygon(victim.GlobalPosition, polygon))
                {
                    capturedStones.Add(victim);
                }
            }
        }

        // 4. Execute Captures
        foreach (var victim in capturedStones)
        {
            victim.Call("on_captured");
        }
    }

    private System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>> BuildAdjacency(List<RigidBody2D> stones)
    {
        var adj = new System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>>();
        var spaceState = GetWorld2D().DirectSpaceState;

        foreach (var s in stones)
        {
            adj[s] = new List<RigidBody2D>();
            var query = new PhysicsShapeQueryParameters2D();
            
            // Use the stone's own shape to find neighbors
            var shapeOwner = s.GetChild<CollisionShape2D>(0); 
            query.Shape = shapeOwner.Shape;
            query.Transform = s.GlobalTransform;
            query.CollideWithAreas = false;
            query.CollideWithBodies = true;
            query.Exclude = new Array<Rid> { s.GetRid() };

            var results = spaceState.IntersectShape(query);
            foreach (var result in results)
            {
                var neighbor = result["collider"].As<RigidBody2D>();
                if (stones.Contains(neighbor))
                {
                    adj[s].Add(neighbor);
                }
            }
        }
        return adj;
    }

    private List<List<RigidBody2D>> FindCycles(List<RigidBody2D> stones, System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>> adj)
    {
        var cycles = new List<List<RigidBody2D>>();
        var visited = new HashSet<RigidBody2D>();

        foreach (var startNode in stones)
        {
            if (visited.Contains(startNode)) continue;

            var parent = new System.Collections.Generic.Dictionary<RigidBody2D, RigidBody2D>();
            var stack = new Stack<RigidBody2D>();
            stack.Push(startNode);

            while (stack.Count > 0)
            {
                var current = stack.Pop();
                if (!visited.Contains(current))
                {
                    visited.Add(current);
                    foreach (var neighbor in adj[current])
                    {
                        if (!visited.Contains(neighbor))
                        {
                            parent[neighbor] = current;
                            stack.Push(neighbor);
                        }
                        else if (parent.ContainsKey(current) && neighbor != parent[current])
                        {
                            // Cycle detected! Backtrace to build the cycle list
                            var cycle = new List<RigidBody2D> { neighbor, current };
                            var temp = current;
                            while (parent.ContainsKey(temp) && parent[temp] != neighbor)
                            {
                                temp = parent[temp];
                                cycle.Add(temp);
                            }
                            cycles.Add(cycle);
                        }
                    }
                }
            }
        }
        return cycles;
    }
}